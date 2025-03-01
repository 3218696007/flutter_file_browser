import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

enum NoEntityOperation {
  refresh,
  create,
  paste,
}

extension NoEntityOperationExtension on NoEntityOperation {
  Icon get icon {
    return switch (this) {
      NoEntityOperation.refresh => const Icon(Icons.refresh),
      NoEntityOperation.create => const Icon(Icons.create_new_folder_outlined),
      NoEntityOperation.paste => const Icon(Icons.content_paste),
    };
  }

  String get label {
    return switch (this) {
      NoEntityOperation.refresh => '刷新',
      NoEntityOperation.create => '新建',
      NoEntityOperation.paste => '粘贴',
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
  property,
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
      EntityOperation.delete =>
        const Icon(Icons.delete_outline, color: Colors.red),
      EntityOperation.property => const Icon(Icons.info_outline),
      EntityOperation.create => const Icon(Icons.create_new_folder_outlined)
    };
  }

  Widget get label {
    return switch (this) {
      EntityOperation.open => const Text('打开'),
      EntityOperation.rename => const Text('重命名'),
      EntityOperation.refresh => const Text('刷新'),
      EntityOperation.cut => const Text('剪切'),
      EntityOperation.copy => const Text('复制'),
      EntityOperation.paste => const Text('粘贴'),
      EntityOperation.delete =>
        const Text('删除', style: TextStyle(color: Colors.red)),
      EntityOperation.property => const Text('属性'),
      EntityOperation.create => const Text('新建'),
    };
  }
}

class EntityOperator {
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

  static Future<String> rename(FileSystemEntity entity, String newName) async {
    try {
      final directory = Directory(entity.path).parent;
      final newPath = '${directory.path}${Platform.pathSeparator}$newName';
      await entity.rename(newPath);
      return '重命名成功';
    } catch (e) {
      return '重命名失败: $e';
    }
  }

  static Future<String> createDirectory(
    String name, {
    required String path,
  }) async {
    try {
      final newDirectory = Directory('$path${Platform.pathSeparator}$name');
      if (newDirectory.existsSync()) return '文件夹已存在';
      await newDirectory.create(recursive: true);
      return '创建成功';
    } catch (e) {
      return '创建失败: $e';
    }
  }

  static Future<String> deleteEntities(
      List<FileSystemEntity> selectedItems) async {
    try {
      for (final entity in selectedItems) {
        entity.delete(recursive: true);
      }
      return '删除成功';
    } catch (e) {
      return '删除失败: $e';
    }
  }

  static Future<String> pasteEntities(
    List<FileSystemEntity> entities, {
    required String path,
  }) async {
    try {
      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final destPath = '$path${Platform.pathSeparator}$name';

        if (entity is File) {
          await _copyFile(entity, destPath);
        } else if (entity is Directory) {
          await _copyDirectory(entity, destPath);
        }
      }
      return '粘贴成功';
    } catch (e) {
      return '粘贴失败: $e';
    }
  }

  static Future<void> _copyFile(File source, String destPath) async {
    String finalPath = destPath;
    int count = 1;

    while (await File(finalPath).exists()) {
      final extension = path.extension(destPath);
      final nameWithoutExtension = path.basenameWithoutExtension(destPath);
      finalPath =
          '${Directory(destPath).parent.path}${Platform.pathSeparator}$nameWithoutExtension ($count)$extension';
      count++;
    }

    await source.copy(finalPath);
  }

  static Future<void> _copyDirectory(Directory source, String destPath) async {
    String finalPath = destPath;
    int count = 1;

    while (await Directory(finalPath).exists()) {
      finalPath = '$destPath ($count)';
      count++;
    }

    final newDir = await Directory(finalPath).create();

    await for (final entity in source.list(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${newDir.path}${Platform.pathSeparator}$name';

      if (entity is File) {
        await _copyFile(entity, newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, newPath);
      }
    }
  }

  static Map<String, dynamic> getFileProperties(FileSystemEntity entity) {
    try {
      final stat = entity.statSync();
      final properties = <String, dynamic>{
        '名称': entity.path.split(Platform.pathSeparator).last,
        '路径': entity.path,
        '修改时间': stat.modified.toString(),
        '访问时间': stat.accessed.toString(),
        '创建时间': stat.changed.toString(),
      };
      if (entity is File) {
        properties['大小'] = '${(entity.lengthSync()) ~/ 1024} KB';
      }
      return properties;
    } catch (e) {
      return {'获取属性失败': e.toString()};
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
