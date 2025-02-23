import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FileOpener {
  static Future<void> openFile(BuildContext context, String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.start('explorer', [filePath]);
      } else if (Platform.isAndroid) {

        final mimeType = _getMimeType(filePath);

        final intent = await const MethodChannel('com.qshh.file_brower/file_opener')
            .invokeMethod(
          'openFile',
          {
            'filePath': filePath,
            'mimeType': mimeType,
          },
        );

        if (intent == false) {
          throw '没有找到可以打开此类型文件的应用';
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('在你的系统中打开文件功能待开发')),
        );
      }
    } catch (e) {
      debugPrint('无法打开文件：$e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开文件：$e')),
        );
      }
    }
  }

  static String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.txt':
        return 'text/plain';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.zip':
        return 'application/zip';
      default:
        return '*/*';
    }
  }
}
