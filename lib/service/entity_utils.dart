import 'dart:io';

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
