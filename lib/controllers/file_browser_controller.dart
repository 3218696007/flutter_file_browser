import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/path_node.dart';

class FileBrowserController with ChangeNotifier {
  List<FileSystemEntity> currentFiles = [];
  final selectedItems = <FileSystemEntity>[];
  String sortBy = 'name';
  String? errorMessage;
  bool isLoading = true;
  bool isListView = true;
  bool _multiSelectMode = false;

  int? indexStartedSelected;
  bool get isMultiSelectMode => _multiSelectMode;
  late PathNode currentNode;

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
    loadCurrentFiles();
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

  Future<void> loadCurrentFiles() async {
    isLoading = true;
    notifyListeners();
    try {
      final directory = Directory(currentNode.path);
      currentFiles = _sortFiles(await directory.list().toList());
      errorMessage = null;
    } catch (e) {
      debugPrint('无法访问该目录: $e');
      errorMessage = '无法访问该目录，可能是因为权限不足。\n请尝试访问其他目录或检查应用权限设置。';
    }
    isLoading = false;
    notifyListeners();
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
    currentFiles = _sortFiles(currentFiles);
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
    if (FileSystemEntity.identicalSync(currentNode.path, newPath)) return;
    currentNode.setChild(PathNode(newPath));
    goForward();
  }

  void goBack() {
    currentNode = currentNode.parent!;
    loadCurrentFiles();
  }

  void goForward() {
    currentNode = currentNode.child!;
    loadCurrentFiles();
  }

  void goUp() => openDirectory(Directory(currentNode.path).parent.path);

  Future<String> renameFile(FileSystemEntity entity, String? newName) async {
    if (newName == null || newName.isEmpty) return '请输入新名称';
    try {
      final directory = Directory(entity.path).parent;
      final newPath = '${directory.path}${Platform.pathSeparator}$newName';
      await entity.rename(newPath);
      loadCurrentFiles();
      return '重命名成功';
    } catch (e) {
      return '重命名失败: $e';
    }
  }

  Future<String> deleteFile(FileSystemEntity entity) async {
    try {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else {
        await entity.delete();
      }
      loadCurrentFiles();
      return '删除成功';
    } catch (e) {
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
      loadCurrentFiles();
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

  // Map<Type, Action<Intent>> get borwserActions {
  //   return {
  //     Intent: CallbackAction<Intent>(
  //       onInvoke: (intent) {
  //         return loadCurrentFiles();
  //       },
  //     ),
  //   };
  // }

  void consecutiveSelecte(int index) {
    if (indexStartedSelected == null) {
      indexStartedSelected = index;
    } else {
      int i = min(indexStartedSelected!, index);
      final end = max(indexStartedSelected!, index);
      while (i <= end) {
        toggleItemSelect(currentFiles[i]);
        i++;
      }
      indexStartedSelected = null;
    }
    notifyListeners();
  }
}

enum BrowserOperation {
  refresh,
  goBack,
  goForward,
  goUp,
  toggleView,
  jumpToPath,
}

extension BrowserOperationExtension on BrowserOperation {
  LogicalKeySet get shortcut {
    return switch (this) {
      BrowserOperation.refresh => LogicalKeySet(LogicalKeyboardKey.f5),
      BrowserOperation.goBack =>
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft),
      BrowserOperation.goForward =>
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight),
      BrowserOperation.goUp =>
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp),
      BrowserOperation.toggleView =>
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyV),
      BrowserOperation.jumpToPath =>
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyL),
    };
  }

  Function? getCallback(FileBrowserController controller) {
    return switch (this) {
      BrowserOperation.refresh => controller.loadCurrentFiles,
      BrowserOperation.goBack =>
        controller.canGoBack ? controller.goBack : null,
      BrowserOperation.goForward =>
        controller.canGoForward ? controller.goForward : null,
      BrowserOperation.goUp => controller.canGoUp ? controller.goUp : null,
      BrowserOperation.toggleView => controller.toggleView,
      BrowserOperation.jumpToPath => null,
    };
  }
}
