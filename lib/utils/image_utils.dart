import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as pp;

/// 从相册选图，复制到 app 目录，返回可读路径
Future<String?> pickAndSaveImage({double maxWidth = 1080, int quality = 90}) async {
  try {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: maxWidth, imageQuality: quality);
    if (xfile == null) return null;
    final bytes = await xfile.readAsBytes();
    final dir = await pp.getApplicationDocumentsDirectory();
    final name = 'bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = File('${dir.path}/$name');
    await saved.writeAsBytes(bytes);
    return saved.path;
  } catch (e) {
    debugPrint('[图片] 选图失败: $e');
    return null;
  }
}
