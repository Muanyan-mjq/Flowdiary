import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/smooth_route.dart';
import '../utils/favorite_storage.dart';
import 'diary_wizard_screen.dart';

/// 日记详情页 — Markdown 渲染
class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  /// 可选：自定义标题，不传则显示日记日期
  final String? title;
  const DiaryDetailScreen({super.key, required this.entry, this.title});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  bool _isFav = false;

  DiaryEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    FavoriteStorage.isFavorite(entry.id).then((v) { if (mounted) setState(() => _isFav = v); });
  }

  void _toggleFav() async {
    final v = await FavoriteStorage.toggle(entry.id);
    if (mounted) setState(() => _isFav = v);
  }

  String _weatherEmoji(String w) {
    switch (w) {
      case '晴': return '☀️';
      case '多云': return '⛅';
      case '阴': return '☁️';
      case '雨': return '🌧️';
      case '雪': return '❄️';
      case '雾': return '🌫️';
      case '雷暴': return '⛈️';
      default: return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey[600]),
              onPressed: () => Navigator.pop(context),
            ),
            center: Text(
              widget.title ?? '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
            right: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, size: 20, color: _isFav ? const Color(0xFFFF6B6B) : const Color(0xFF666666)),
                onPressed: _toggleFav,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF666666)),
                onPressed: () => _editEntry(context),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 标签行
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (entry.weather.isNotEmpty)
                    _tag('${_weatherEmoji(entry.weather)} ${entry.weather}', const Color(0xFF87CEEB)),
                  if (entry.mood.isNotEmpty)
                    _tag('😊 ${entry.mood}', const Color(0xFFFF9800)),
                  ...entry.events.map((e) => _tag(e, const Color(0xFF4CAF50))),
                ]),
                const SizedBox(height: 24),
                // Markdown 渲染正文
                ..._renderMarkdown(entry.content),
                // 日记配图
                if (entry.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildImageGallery(),
                ],
                const SizedBox(height: 32),
                Center(
                  child: Text('${entry.createdAt.year}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.day.toString().padLeft(2, '0')}  '
                      '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 简单 Markdown → Widget 渲染
  List<Widget> _renderMarkdown(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    final bodyStyle = const TextStyle(fontSize: 17, height: 1.8, color: Color(0xFF333333));

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 分割线
      if (line.trim() == '---') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Colors.grey[300], thickness: 1),
        ));
        continue;
      }
      // 标题
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(line.substring(4), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Text(line.substring(3), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        ));
        continue;
      }
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(line.substring(2), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        ));
        continue;
      }
      // 待办
      if (line.startsWith('- [ ] ') || line.startsWith('- [x] ')) {
        final checked = line.startsWith('- [x] ');
        final content = line.substring(6);
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20, color: checked ? const Color(0xFF4CAF50) : Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(child: Text(content, style: TextStyle(
                fontSize: 16, height: 1.5,
                color: checked ? Colors.grey[500] : const Color(0xFF333333),
                decoration: checked ? TextDecoration.lineThrough : null))),
          ]),
        ));
        continue;
      }
      // 引用
      if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: Color(0xFF4ACBD4), width: 3)),
          ),
          child: Text(line.substring(2), style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
        ));
        continue;
      }
      // 无序列表
      if (line.startsWith('- ') && !line.startsWith('- [')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
            Expanded(child: _renderInline(line.substring(2), bodyStyle)),
          ]),
        ));
        continue;
      }
      // 有序列表
      final olMatch = RegExp(r'^(\d+)\.\s(.+)$').firstMatch(line);
      if (olMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${olMatch.group(1)}. ', style: const TextStyle(fontSize: 16, color: Color(0xFF999999))),
            Expanded(child: _renderInline(olMatch.group(2)!, bodyStyle)),
          ]),
        ));
        continue;
      }
      // 空行
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      // 普通行（含行内格式）
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: _renderInline(line, bodyStyle),
      ));
    }
    return widgets;
  }

  /// 行内格式：粗体、斜体、代码
  Widget _renderInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    // 简单正则解析 **bold** *italic* `code`
    final regex = RegExp(r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(text: match.group(2),
            style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(4),
            style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(text: match.group(6),
            style: base.copyWith(fontFamily: 'monospace', backgroundColor: const Color(0xFFF0F0F0), fontSize: base.fontSize! - 2)));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return RichText(text: TextSpan(style: base, children: spans));
  }

  /// 图片画廊（横向滚动，点击放大）
  Widget _buildImageGallery() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: entry.imagePaths.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _previewImage(context, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(entry.imagePaths[i]),
                  width: 100, height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100, height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 图片放大预览
  void _previewImage(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(entry.imagePaths[index]), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Widget _safeImg(String path, {double? w, BoxFit fit = BoxFit.cover}) {
    try {
      return Image.file(File(path), width: w, fit: fit,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _editEntry(BuildContext context) {
    Navigator.push(context, SmoothRoute(builder: (_) => DiaryWizardScreen(editTarget: entry)));
  }
}
