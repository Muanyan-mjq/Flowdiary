import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/responsive_app_bar.dart';
import 'daily_sign_square_screen.dart';

class DailySignShareScreen extends StatefulWidget {
  final DailySignPost post;
  const DailySignShareScreen({super.key, required this.post});

  @override State<DailySignShareScreen> createState() => _DailySignShareScreenState();
}

class _DailySignShareScreenState extends State<DailySignShareScreen> {
  final _repaintKey = GlobalKey();
  bool _isMinimal = false;
  bool _generating = false;

  static const _papers = [Color(0xFFFFFEF0), Color(0xFFFFF8EC), Color(0xFFFFF3E0), Color(0xFFFDF8F0), Color(0xFFFFFAF0), Color(0xFFFFF5EE)];

  String get _weekDay {
    const d = ['日', '一', '二', '三', '四', '五', '六'];
    return '星期${d[DateTime.now().weekday % 7]}';
  }

  @override Widget build(BuildContext c) {
    final st = ResponsiveAppBar.safeTop(c);
    return Scaffold(backgroundColor: const Color(0xFFE8E8E8), body: Column(children: [
      SizedBox(height: st),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(c), child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)]), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF555555)))),
        const Spacer(),
        const Text('生成分享卡片', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const Spacer(),
        GestureDetector(onTap: () => setState(() => _isMinimal = !_isMinimal), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: _isMinimal ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_isMinimal ? Icons.dark_mode : Icons.style, size: 16, color: _isMinimal ? Colors.white : const Color(0xFF555555)), const SizedBox(width: 4), Text(_isMinimal ? '简约' : '便签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isMinimal ? Colors.white : const Color(0xFF555555)))]))),
      ])),
      Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildCard()))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _generating ? null : _generate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: _generating ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存并分享', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))))),
    ]));
  }

  Widget _buildCard() {
    final p = widget.post;
    final now = DateTime.now();
    final date = '${now.year}.${now.month}.${now.day}  $_weekDay';
    final bg = _isMinimal ? const Color(0xFF1A1A2E) : _papers[p.userName.hashCode.abs() % _papers.length];
    final isDark = _isMinimal;

    return RepaintBoundary(key: _repaintKey, child: Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 28),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!_isMinimal) ...[
          // ═══ 便签风 ═══
          _buildPin(), const SizedBox(height: 8),
          Text('"', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: const Color(0xFFD4A574).withValues(alpha: 0.25), height: 0.5)),
          const SizedBox(height: 16),
          Text(p.content, style: const TextStyle(fontSize: 22, height: 1.8, color: Color(0xFF4A3728), fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          // 装饰分割线
          Row(children: [Expanded(child: Divider(color: const Color(0xFFD4A574).withValues(alpha: 0.3), thickness: 1)), const SizedBox(width: 12), Icon(Icons.auto_awesome, size: 14, color: const Color(0xFFD4A574).withValues(alpha: 0.4)), const SizedBox(width: 12), Expanded(child: Divider(color: const Color(0xFFD4A574).withValues(alpha: 0.3), thickness: 1))]),
          const SizedBox(height: 20),
          // 信息行
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('— ${p.userName}', style: const TextStyle(fontSize: 14, color: Color(0xFFA09080), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFFC0B0A0))),
            ]),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF5ECD7), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8D5B0))), child: const Text('随心耶', style: TextStyle(fontSize: 10, color: Color(0xFFB8956A), fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 18),
          // 底部 QR
          Row(children: [
            const Text('扫码查看更多', style: TextStyle(fontSize: 9, color: Color(0xFFC0B0A0))),
            const Spacer(),
            Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE8D5B0))), padding: const EdgeInsets.all(4), child: QrImageView(data: 'https://muanyan-mjq.github.io', size: 44, backgroundColor: Colors.white, eyeStyle: QrEyeStyle(color: const Color(0xFF8B7355)), dataModuleStyle: QrDataModuleStyle(color: const Color(0xFF8B7355)))),
          ]),
        ] else ...[
          // ═══ 简约风 ═══
          const SizedBox(height: 12),
          Container(width: 40, height: 3, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 28),
          Text(p.content, style: TextStyle(fontSize: 24, height: 1.7, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w300)),
          const SizedBox(height: 36),
          Row(children: [Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))), const SizedBox(width: 16), Icon(Icons.auto_awesome, size: 12, color: Colors.white.withValues(alpha: 0.2)), const SizedBox(width: 16), Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1)))]),
          const SizedBox(height: 24),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('— ${p.userName}', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.25))),
            ]),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)), child: Text('随心耶', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Text('扫码查看更多', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.15))),
            const Spacer(),
            QrImageView(data: 'https://muanyan-mjq.github.io', size: 44, backgroundColor: Colors.transparent, eyeStyle: QrEyeStyle(color: Colors.white.withValues(alpha: 0.4)), dataModuleStyle: QrDataModuleStyle(color: Colors.white.withValues(alpha: 0.4))),
          ]),
        ],
      ]),
    ));
  }

  Widget _buildPin() => Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFF8B5E3C), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(1, 2))]));

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final b = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return;
      final img = await b.toImage(pixelRatio: 3);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return;
      final bytes = bd.buffer.asUint8List();
      final name = '随心耶_${DateTime.now().millisecondsSinceEpoch}';
      // 保存到临时文件
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(bytes);
      // 尝试保存到相册
      try {
        await ImageGallerySaver.saveImage(bytes, quality: 90, name: name);
      } catch (_) {
        // 相册保存失败不影响分享
      }
      // 分享
      await Share.shareXFiles([XFile(file.path)], text: widget.post.content);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已生成并分享')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
