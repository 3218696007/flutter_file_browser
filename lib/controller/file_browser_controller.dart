import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../model/path_node.dart';
import '../service/file_opener.dart';

class FileBrowserController with ChangeNotifier {
  List<FileSystemEntity> entities = [];
  final selectedItems = <FileSystemEntity>[];
  String sortBy = 'name';
  String? _errorMessage;
  DateTime _lastTapTime = DateTime(0);
  int _lastTapIndex = -1;

  void setErrorMessageAndNotify(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  String? get errorMessage => _errorMessage;

  bool isLoading = true;
  bool isListView = true;
  bool _multiSelectMode = false;

  int? indexStartedSelected;
  bool get isMultiSelectMode => _multiSelectMode;
  late PathNode currentNode;

  Map<ShortcutActivator, VoidCallback> get shortcutbindings {
    return Map.fromEntries(ShortcutOperation.values.map(
      (op) => op.getShortcutAndCallback(this),
    ));
  }

  void cancelMultiSelect() {
    selectedItems.clear();
    _multiSelectMode = false;
    notifyListeners();
  }

  void enterMultiSelectMode() {
    _multiSelectMode = true;
    notifyListeners();
  }

  Future<void> initialize(String? initialPath) async {
    currentNode = PathNode(initialPath ?? await getRootPath());
    loadFilesAndNotify();
  }

  Future<String> getRootPath() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path.split('Android')[0] ?? '/';
    } else if (Platform.isWindows) {
      return 'C:\\';
    } else {
      return '/';
    }
  }

  bool get canGoUp {
    final parentDirectory = Directory(currentNode.path).parent;
    return parentDirectory.existsSync() &&
        parentDirectory.path != currentNode.path;
  }

  bool get canGoBack => currentNode.parent != null;

  bool get canGoForward => currentNode.child != null;

  Future<void> loadFilesAndNotify() async {
    isLoading = true;
    notifyListeners();
    try {
      final directory = Directory(currentNode.path);
      entities = _sortFiles(await directory.list().toList());
      isLoading = false;
      setErrorMessageAndNotify(null);
    } on Exception catch (e) {
      isLoading = false;
      setErrorMessageAndNotify('无法访问该目录: $e');
    }
  }

  List<FileSystemEntity> _sortFiles(List<FileSystemEntity> files) {
    switch (sortBy) {
      case 'name':
        return files
          ..sort(
              (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      case 'date':
        return files
          ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      case 'size':
        return files
          ..sort((a, b) {
            if (a is Directory && b is File) return -1;
            if (a is File && b is Directory) return 1;
            if (a is File && b is File) {
              return b.lengthSync().compareTo(a.lengthSync());
            }
            return 0;
          });
      default:
        return files;
    }
  }

  void changeSortMethod(String method) {
    sortBy = method;
    entities = _sortFiles(entities);
    notifyListeners();
  }

  DateTime _lastPopTime = DateTime(0);

  bool cantPopOrBack() {
    if (canGoBack) {
      goBack();
      return false;
    }
    final now = DateTime.now();
    if (now.difference(_lastPopTime) <= const Duration(seconds: 2)) exit(0);
    _lastPopTime = now;
    return true;
  }

  void openDirectory(String newPath) {
    try {
      if (FileSystemEntity.identicalSync(currentNode.path, newPath)) return;
    } catch (_) {}
    currentNode.setChild(PathNode(newPath));
    goForward();
  }

  void goBack() {
    currentNode = currentNode.parent!;
    loadFilesAndNotify();
  }

  void goForward() {
    currentNode = currentNode.child!;
    loadFilesAndNotify();
  }

  void goUp() => openDirectory(Directory(currentNode.path).parent.path);

  Future<String> renameFile(FileSystemEntity entity, String? newName) async {
    if (newName == null || newName.isEmpty) return '请输入新名称';
    try {
      final directory = Directory(entity.path).parent;
      final newPath = '${directory.path}${Platform.pathSeparator}$newName';
      await entity.rename(newPath);
      loadFilesAndNotify();
      return '重命名成功';
    } catch (e) {
      return '重命名失败: $e';
    }
  }

  Future<String> deleteEntitiesToRecycle() async {
    try {
      for (final entity in selectedItems) {
        // TODO 删除到回收站
        await entity.delete(recursive: true);
        // if (entity is Directory) {
        //   await entity.delete(recursive: true);
        // } else {
        //   await entity.delete();
        // }
      }
      cancelMultiSelect();
      loadFilesAndNotify();
      return '删除成功';
    } catch (e) {
      cancelMultiSelect();
      return '删除失败: $e';
    }
  }

  Map<String, dynamic> getFileProperties(FileSystemEntity entity) {
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
      throw '获取属性失败: $e';
    }
  }

  Future<String> createDirectory(String? folderName) async {
    final newPath = '${currentNode.path}/$folderName';
    try {
      await Directory(newPath).create();
      loadFilesAndNotify();
      return '创建成功';
    } on Exception catch (e) {
      return '创建失败: $e';
    }
  }

  void toggleItemSelect(FileSystemEntity entity) {
    if (selectedItems.contains(entity)) {
      selectedItems.remove(entity);
    } else {
      selectedItems.add(entity);
    }
    notifyListeners();
  }

  void toggleView() {
    isListView = !isListView;
    notifyListeners();
  }

  void consecutiveSelecte(int index) {
    if (indexStartedSelected == null) {
      indexStartedSelected = index;
    } else {
      int i = min(indexStartedSelected!, index);
      final end = max(indexStartedSelected!, index);
      while (i <= end) {
        toggleItemSelect(entities[i]);
        i++;
      }
      indexStartedSelected = null;
    }
    notifyListeners();
  }

  void openItem(FileSystemEntity entity) {
    if (entity is Directory) {
      openDirectory(entity.path);
    } else {
      FileOpener.openFile(entity.path);
    }
  }

  void onTapItem(FileSystemEntity entity) {
    if (isMultiSelectMode) {
      toggleItemSelect(entity);
    } else if (Platform.isAndroid) {
      openItem(entity);
    } else {
      const doubleTapDelay = Duration(milliseconds: 300);
      final now = DateTime.now();
      final index = entities.indexOf(entity);
      if (now.difference(_lastTapTime) < doubleTapDelay &&
          index == _lastTapIndex) {
        openItem(entity);
      } else {
        selectedItems.clear();
        toggleItemSelect(entity);
        _lastTapTime = now;
        _lastTapIndex = index;
      }
    }
  }
}

enum ShortcutOperation {
  refresh,
  goBack,
  goForward,
  goUp,
  toggleView,
  delete,
}

extension BrowserOperationExtension on ShortcutOperation {
  MapEntry<ShortcutActivator, VoidCallback> getShortcutAndCallback(
      FileBrowserController controller) {
    return switch (this) {
      ShortcutOperation.refresh => MapEntry(
          const SingleActivator(LogicalKeyboardKey.f5),
          controller.loadFilesAndNotify,
        ),
      ShortcutOperation.goBack => MapEntry(
          const SingleActivator(alt: true, LogicalKeyboardKey.arrowLeft),
          () {
            if (controller.canGoBack) controller.goBack();
          },
        ),
      ShortcutOperation.goForward => MapEntry(
          const SingleActivator(alt: true, LogicalKeyboardKey.arrowRight),
          () {
            if (controller.canGoForward) controller.goForward();
          },
        ),
      ShortcutOperation.goUp => MapEntry(
          const SingleActivator(alt: true, LogicalKeyboardKey.arrowUp),
          () {
            if (controller.canGoUp) controller.goUp();
          },
        ),
      ShortcutOperation.toggleView => MapEntry(
          const SingleActivator(alt: true, LogicalKeyboardKey.keyV),
          controller.toggleView,
        ),
      ShortcutOperation.delete => MapEntry(
          const SingleActivator(LogicalKeyboardKey.delete),
          () => controller.deleteEntitiesToRecycle(),
        ),
    };
  }
}
