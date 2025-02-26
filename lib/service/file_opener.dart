import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FileOpener {
  static Future openFile(String filePath) async {
    if (Platform.isWindows) {
      await Process.start('explorer', [filePath]);
    } else if (Platform.isAndroid) {
      final mimeType = _getMimeType(filePath);
      final intent =
          await const MethodChannel('com.qshh.file_browser/file_opener')
              .invokeMethod(
        'openFile',
        {
          'filePath': filePath,
          'mimeType': mimeType,
        },
      );
      if (intent == false) {
        // TODO: 打开文件失败的处理逻辑
      }
    } else {
      // TODO: 其他平台的文件打开逻辑
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
