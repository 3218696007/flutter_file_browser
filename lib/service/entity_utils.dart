import 'dart:io';

import 'package:flutter/material.dart';

enum EntityOperation {
  open,
  rename,
  cut,
  copy,
  paste,
  delete,
  properties,
}

enum EntityType {
  image,
  archive,
  audio,
  video,
  pdf,
  word,
  excel,
  document,
  mindMap,
  unknown,
  ppt,
}

extension EntityExtension on FileSystemEntity {
  String get name => path.split(Platform.pathSeparator).last;

  int? get size {
    try {
      return (this as File).lengthSync();
    } catch (_) {
      return null;
    }
  }

  EntityType get type {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'cr2':
        return EntityType.image;
      case 'zip':
      case 'rar':
      case '7z':
        return EntityType.archive;
      case 'mp3':
      case 'wav':
      case 'flac':
        return EntityType.audio;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return EntityType.video;
      case 'doc':
      case 'docx':
        return EntityType.word;
      case 'xls':
      case 'xlsx':
        return EntityType.excel;
      case 'ppt':
      case 'pptx':
        return EntityType.ppt;
      case 'pdf':
        return EntityType.pdf;
      case 'txt':
        return EntityType.document;
      case 'xmind':
        return EntityType.mindMap;
      default:
        return EntityType.unknown;
    }
  }
}

extension EntityOperationExtension on EntityOperation {
  Icon get icon {
    switch (this) {
      case EntityOperation.open:
        return const Icon(Icons.open_in_new);
      case EntityOperation.rename:
        return const Icon(Icons.drive_file_rename_outline);
      case EntityOperation.cut:
        return const Icon(Icons.content_cut);
      case EntityOperation.copy:
        return const Icon(Icons.content_copy);
      case EntityOperation.paste:
        return const Icon(Icons.content_paste);
      case EntityOperation.delete:
        return const Icon(Icons.delete_outline);
      case EntityOperation.properties:
        return const Icon(Icons.info_outline);
    }
  }

  String get label {
    switch (this) {
      case EntityOperation.open:
        return '打开';
      case EntityOperation.rename:
        return '重命名';
      case EntityOperation.cut:
        return '剪切';
      case EntityOperation.copy:
        return '复制';
      case EntityOperation.paste:
        return '粘贴';
      case EntityOperation.delete:
        return '删除';
      case EntityOperation.properties:
        return '属性';
    }
  }
}
