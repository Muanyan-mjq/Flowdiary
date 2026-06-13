import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/image_utils.dart';

const _bgPresets = [null, 0xFFFFF8E7, 0xFFF0F0F0, 0xFF1A1A2E, 0xFFE8F5E9, 0xFFFFF0F5];
const _bgLabels = ['默认', '羊皮纸', '浅灰', '暗黑', '护眼', '樱花'];

/// 可用的字号列表
const _fontSizes = [14.0, 16.0, 18.0, 20.0, 22.0];
const _fontSizeLabels = ['小', '中', '大', '特大', '超大'];

class _MdCtrl extends TextEditingController {
  _MdCtrl({String? text}) : super(text: text);
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final base = style ?? const TextStyle();
    if (text.isEmpty) return TextSpan(text: '', style: base);
    final lines = text.split('\n');
    final spans = <InlineSpan>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('# ') && line.length > 2) {
        spans.add(TextSpan(text: line.substring(2), style: base.copyWith(fontSize: (base.fontSize ?? 16) + 6, fontWeight: FontWeight.w800)));
      } else if (line.startsWith('- [ ] ')) {
        spans.add(TextSpan(text: '☐ ${line.substring(6)}', style: base));
      } else if (line.startsWith('- [x] ')) {
        spans.add(TextSpan(text: '☑ ${line.substring(6)}', style: base.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey)));
      } else if (line.startsWith('> ')) {
        spans.add(TextSpan(text: line.substring(2), style: base.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic)));
      } else if (line.startsWith('- ') && line.length > 2) {
        spans.add(_parseInline('• ${line.substring(2)}', base));
      } else {
        spans.add(_parseInline(line, base));
      }
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return TextSpan(style: base, children: spans);
  }

  TextSpan _parseInline(String t, TextStyle base) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'(\*\*(.+?)\*\*)|(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)|(`(.+?)`)');
    int pos = 0;
    for (final m in re.allMatches(t)) {
      if (m.start > pos) spans.add(TextSpan(text: t.substring(pos, m.start), style: base));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(2)!, style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(text: m.group(3)!, style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(text: m.group(6)!, style: base.copyWith(fontFamily: 'monospace', fontSize: (base.fontSize ?? 16) - 1, backgroundColor: Colors.grey[200])));
      }
      pos = m.end;
    }
    if (pos < t.length) spans.add(TextSpan(text: t.substring(pos), style: base));
    if (spans.isEmpty) spans.add(TextSpan(text: t, style: base));
    return TextSpan(children: spans);
  }
}

class WritingStep extends StatefulWidget {
  final String? initialText;
  final int? initialBgColor;
  final List<String>? initialImagePaths;
  final Function(String) onWriteText;
  final Function(int?) onBgColorChanged;
  final Function(List<String>) onImagePathsChanged;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const WritingStep({
    super.key,
    this.initialText,
    this.initialBgColor,
    this.initialImagePaths,
    required this.onWriteText,
    required this.onBgColorChanged,
    required this.onImagePathsChanged,
    this.onBack,
    this.onSave,
  });

  @override
  State<WritingStep> createState() => _WritingStepState();
}

class _WritingStepState extends State<WritingStep> with SingleTickerProviderStateMixin {
  late final _MdCtrl _ctrl;
  late final FocusNode _focus;
  int _chars = 0;
  int? _bgColor;
  double _fontSize = 16;
  List<String> _imagePaths = [];
  final _speech = stt.SpeechToText();
  bool _speechOk = false;
  bool _listening = false;
  late final AnimationController _in;
  late final Animation<double> _fade;

  // 撤销栈（最多 20 步）
  final List<_EditSnapshot> _undoStack = [];
  final List<_EditSnapshot> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _ctrl = _MdCtrl(text: widget.initialText ?? '');
    _focus = FocusNode();
    _chars = _ctrl.text.length;
    _bgColor = widget.initialBgColor;
    _imagePaths = List<String>.from(widget.initialImagePaths ?? []);
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);
    _in.forward();
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _focus.requestFocus(); });
    // 语音初始化异步进行，不阻塞 UI
    _speech.initialize().then((ok) { if (mounted) setState(() => _speechOk = ok); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _in.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _onChanged(String t) {
    // 记录撤销快照
    if (_undoStack.isEmpty || _undoStack.last.text != t) {
      _undoStack.add(_EditSnapshot(text: t, selection: _ctrl.selection));
      if (_undoStack.length > 20) _undoStack.removeAt(0);
      _redoStack.clear();
    }
    setState(() => _chars = t.length);
    widget.onWriteText(t);
  }

  /// 选中文字 → 包裹标记；无选中 → 光标插入空标记
  void _wrap(String marker) {
    final sel = _ctrl.selection;
    if (sel.isValid && sel.start != sel.end) {
      final s = _ctrl.text.substring(sel.start, sel.end);
      _ctrl.text = _ctrl.text.substring(0, sel.start) + marker + s + marker + _ctrl.text.substring(sel.end);
      _ctrl.selection = TextSelection(baseOffset: sel.start, extentOffset: sel.start + marker.length * 2 + s.length);
    } else {
      final pos = sel.isValid ? sel.start : _ctrl.text.length;
      _ctrl.text = _ctrl.text.substring(0, pos) + marker + marker + _ctrl.text.substring(pos);
      _ctrl.selection = TextSelection.collapsed(offset: pos + marker.length);
    }
    _onChanged(_ctrl.text);
    _focus.requestFocus();
  }

  void _insert(String text) {
    final cur = _ctrl.text;
    final pos = _ctrl.selection.isValid ? _ctrl.selection.start : cur.length;
    String ins = text;
    if (pos > 0 && cur[pos - 1] != '\n' && (text.startsWith('#') || text == '- ' || text == '- [ ] ' || text == '> ')) {
      ins = '\n$text';
    }
    _ctrl.text = cur.substring(0, pos) + ins + cur.substring(pos);
    _ctrl.selection = TextSelection.collapsed(offset: pos + ins.length);
    _onChanged(_ctrl.text);
    _focus.requestFocus();
  }

  /// 撤销
  void _undo() {
    if (_undoStack.length < 2) return;
    _redoStack.add(_undoStack.removeLast());
    final prev = _undoStack.last;
    _ctrl.text = prev.text;
    _ctrl.selection = prev.selection;
    _onChanged(prev.text);
  }

  /// 重做
  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _ctrl.text = next.text;
    _ctrl.selection = next.selection;
    _onChanged(next.text);
  }

  /// 语音输入（离线时优雅降级）
  void _toggleVoice() async {
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_speechOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('语音输入不可用。请检查：\n1. 麦克风权限是否开启\n2. 网络连接是否正常（中文语音需联网）'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (r.finalResult && mounted && r.recognizedWords.isNotEmpty) {
          final cur = _ctrl.text;
          final p = _ctrl.selection.isValid ? _ctrl.selection.start : cur.length;
          final pf = (p > 0 && cur[p - 1] != '\n' && cur[p - 1] != ' ') ? ' ' : '';
          _ctrl.text = cur.substring(0, p) + pf + r.recognizedWords + cur.substring(p);
          _ctrl.selection = TextSelection.collapsed(offset: p + pf.length + r.recognizedWords.length);
          _onChanged(_ctrl.text);
          setState(() => _listening = false);
        }
      },
      localeId: 'zh_CN',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// 添加配图
  Future<void> _addImage() async {
    final path = await pickAndSaveImage(maxWidth: 1080, quality: 85);
    if (path != null && mounted) {
      setState(() => _imagePaths.add(path));
      widget.onImagePathsChanged(_imagePaths);
    }
  }

  /// 删除配图
  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
    widget.onImagePathsChanged(_imagePaths);
  }

  void _showBgPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          const Text('页面背景', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(spacing: 14, runSpacing: 14, children: List.generate(_bgPresets.length, (i) {
            final c = _bgPresets[i];
            final sel = _bgColor == c;
            return GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _bgColor = c);
                widget.onBgColorChanged(c);
              },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: c != null ? Color(c) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: sel ? Border.all(color: const Color(0xFF4ACBD4), width: 3) : Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: sel ? const Icon(Icons.check_rounded, size: 22, color: Color(0xFF4ACBD4)) : null,
              ),
            );
          })),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(_bgLabels.length, (i) => SizedBox(width: 48, child: Text(_bgLabels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[500]))))),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () { Navigator.pop(ctx); setState(() => _bgColor = null); widget.onBgColorChanged(null); },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('恢复默认'),
          ),
        ]),
      ),
    );
  }

  bool get _isDark => _bgColor == 0xFF1A1A2E;
  Color get _textColor => _isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF333333);
  Color get _hintColor => _isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFC0C0C0);
  Color get _barBg => _isDark ? const Color(0xFF252530) : Colors.white;
  Color get _iconColor => _isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF555555);
  Color get _barDivider => _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

  @override
  Widget build(BuildContext context) {
    final has = _ctrl.text.trim().isNotEmpty;
    final bot = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _in,
      builder: (_, child) => Opacity(opacity: _fade.value, child: child),
      child: Container(
        decoration: _bgColor != null ? BoxDecoration(color: Color(_bgColor!)) : null,
        child: Column(children: [
          // ═══ 顶部状态栏：字数 + 保存按钮 ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
            child: Row(children: [
              // 字数统计
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_chars 字', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _iconColor.withValues(alpha: 0.6))),
              ),
              const Spacer(),
              // 保存按钮
              GestureDetector(
                onTap: has ? widget.onSave : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: has ? const Color(0xFF4ACBD4) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: has ? [BoxShadow(color: const Color(0xFF4ACBD4).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                  ),
                  child: Text('保存', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: has ? Colors.white : const Color(0xFFBBBBBB))),
                ),
              ),
            ]),
          ),
          // ═══ 配图预览条（如有） ═══
          if (_imagePaths.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _imagePaths.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_imagePaths[i]), width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 20, color: Colors.grey))),
                      ),
                      Positioned(
                        top: -4, right: -4,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // ═══ 编辑区 ═══
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onChanged,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                cursorColor: const Color(0xFF4ACBD4),
                style: TextStyle(fontSize: _fontSize, height: 1.8, color: _textColor),
                decoration: InputDecoration(
                  hintText: '这一刻在想什么...',
                  hintStyle: TextStyle(fontSize: 15, color: _hintColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // ═══ 底部工具栏（两行：格式 + 功能） ═══
          Container(
            color: _barBg,
            padding: EdgeInsets.only(bottom: bot),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Divider(height: 1, color: _barDivider),
              // 第一行：格式工具
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _toolBtn(Icons.undo, _undo, tooltip: '撤销', enabled: _undoStack.length >= 2),
                    _toolBtn(Icons.redo, _redo, tooltip: '重做', enabled: _redoStack.isNotEmpty),
                    _sep(),
                    _toolBtn(Icons.format_bold, () => _wrap('**'), tooltip: '加粗'),
                    _toolBtn(Icons.format_italic, () => _wrap('*'), tooltip: '斜体'),
                    _toolBtn(Icons.title, () => _insert('# '), tooltip: '标题'),
                    _toolBtn(Icons.format_quote, () => _insert('> '), tooltip: '引用'),
                    _sep(),
                    _toolBtn(Icons.format_list_bulleted, () => _insert('- '), tooltip: '无序列表'),
                    _toolBtn(Icons.check_box_outlined, () => _insert('- [ ] '), tooltip: '待办'),
                  ],
                ),
              ),
              // 第二行：功能工具 + 字号
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _fontSizeBtn(),
                    _sep(),
                    _toolBtn(Icons.image_outlined, _addImage, tooltip: '添加配图'),
                    _toolBtn(Icons.palette_outlined, _showBgPicker, tooltip: '背景色'),
                    _toolBtn(
                      _listening ? Icons.mic : Icons.keyboard_voice_outlined,
                      _toggleVoice,
                      tooltip: _listening ? '停止语音' : '语音输入',
                      active: _listening,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// 分隔线
  Widget _sep() => Container(width: 1, height: 20, color: _barDivider);

  /// 字号切换按钮
  Widget _fontSizeBtn() {
    final idx = _fontSizes.indexOf(_fontSize);
    final label = _fontSizeLabels[idx];
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _fontSize = _fontSizes[(idx + 1) % _fontSizes.length];
        });
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _iconColor)),
            Text('Aa', style: TextStyle(fontSize: 9, color: _iconColor.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap, {String? tooltip, bool active = false, bool enabled = true}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: enabled ? () { HapticFeedback.lightImpact(); onTap(); } : null,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.redAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? (active ? Colors.redAccent : _iconColor) : _iconColor.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}

/// 编辑快照（用于撤销/重做）
class _EditSnapshot {
  final String text;
  final TextSelection selection;
  const _EditSnapshot({required this.text, required this.selection});
}
