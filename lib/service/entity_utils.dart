import 'dart:io';

import 'package:flutter/material.dart';

enum EmptyEntityOperation {
  refresh,
  create,
  paste,
}

extension EmptyEntityOperationExtension on EmptyEntityOperation {
  Icon get icon {
    return switch (this) {
      EmptyEntityOperation.refresh => const Icon(Icons.refresh),
      EmptyEntityOperation.create =>
        const Icon(Icons.create_new_folder_outlined),
      EmptyEntityOperation.paste => const Icon(Icons.content_paste),
    };
  }

  String get label {
    return switch (this) {
      EmptyEntityOperation.refresh => '刷新',
      EmptyEntityOperation.create => '新建',
      EmptyEntityOperation.paste => '粘贴',
    };
  }
}

enum EntityOperation {
  open,
  rename,
  refresh,
  create,
  cut,
  copy,
  paste,
  delete,
  properties,
}

extension EntityOperationExtension on EntityOperation {
  Icon get icon {
    return switch (this) {
      EntityOperation.open => const Icon(Icons.open_in_new),
      EntityOperation.rename => const Icon(Icons.drive_file_rename_outline),
      EntityOperation.refresh => const Icon(Icons.refresh),
      EntityOperation.cut => const Icon(Icons.content_cut),
      EntityOperation.copy => const Icon(Icons.content_copy),
      EntityOperation.paste => const Icon(Icons.content_paste),
      EntityOperation.delete => const Icon(Icons.delete_outline),
      EntityOperation.properties => const Icon(Icons.info_outline),
      EntityOperation.create => const Icon(Icons.create_new_folder_outlined)
    };
  }

  String get label {
    return switch (this) {
      EntityOperation.open => '打开',
      EntityOperation.rename => '重命名',
      EntityOperation.refresh => '刷新',
      EntityOperation.cut => '剪切',
      EntityOperation.copy => '复制',
      EntityOperation.paste => '粘贴',
      EntityOperation.delete => '删除',
      EntityOperation.properties => '属性',
      EntityOperation.create => '新建'
    };
  }
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
