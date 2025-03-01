import 'dart:io';

import 'package:flutter/foundation.dart';
import '../service/entity_extension.dart';

class BrowserClipboard with ChangeNotifier {
  BrowserClipboard._();

  static bool _fromCut = false;

  static final canPaste = ValueNotifier(false);

  static final List<FileSystemEntity> _entities = [];

  static void _refresh() {
    canPaste.value = _entities.isNotEmpty;
  }

  static void copy(List<FileSystemEntity> entities,
      {bool fromCut = false}) async {
    _entities.clear();
    _entities.addAll(entities);
    _refresh();
    _fromCut = fromCut;
  }

  static Future<List<String>> paste(String path) async {
    final List<String> messages = [];
    for (var entity in _entities) {
      var targetPath = '$path${Platform.pathSeparator}${entity.name}';
      if (entity is File) {
        if (await File(targetPath).exists()) {
          messages.add('${entity.name}已存在');
        }
        await entity.copy(targetPath);
        messages.add('${entity.name}复制成功');
      } else if (entity is Directory) {
        messages.add(await _copyDirectory(entity, targetPath));
      }
    }
    if (_fromCut) {
      for (var entity in _entities) {
        await entity.delete();
      }
      _entities.clear();
      _refresh();
    }
    return messages;
  }

  static Future<String> _copyDirectory(
      Directory source, String destPath) async {
    if (await Directory(destPath).exists()) {
      return '文件夹${source.name}已存在';
    }
    await for (final entity in source.list(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final newPath = '$destPath${Platform.pathSeparator}$name';
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, newPath);
      }
    }
    return '复制成功';
  }
}
