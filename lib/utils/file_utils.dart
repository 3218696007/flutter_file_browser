import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum FileType {
  image,
  archive,
  audio,
  video,
  pdf,
  document,
  mindMap,
  unknown,
}

class FileUtils {
  static Future<bool> requestStoragePermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    } else if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  static Future<Directory?> getInitialDirectory() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final rootDir = externalDir.path.split('Android')[0];
        return Directory(rootDir);
      }
    } catch (e) {
      debugPrint('Error getting initial directory: $e');
    }
    return Directory('/');
  }

  static String getFileName(FileSystemEntity entity) {
    return entity.path.split('/').last;
  }

  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  static FileType getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return FileType.image;
      case 'zip':
      case 'rar':
      case '7z':
        return FileType.archive;
      case 'mp3':
      case 'wav':
      case 'flac':
        return FileType.audio;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return FileType.video;
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
      case 'txt':
        return FileType.document;
      case 'xmind':
        return FileType.mindMap;
      default:
        return FileType.unknown;
    }
  }
}
