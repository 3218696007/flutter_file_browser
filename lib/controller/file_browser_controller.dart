import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../model/path_node.dart';
import '../service/entity_operator.dart';

class FileBrowserController with ChangeNotifier {
  List<FileSystemEntity> entities = [];
  final selectedEntities = <FileSystemEntity>[];
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

  void cancelMultiSelect() {
    selectedEntities.clear();
    _multiSelectMode = false;
    notifyListeners();
  }

  void enterMultiSelectMode() {
    _multiSelectMode = true;
    notifyListeners();
  }

  Future<void> initialize(String? initialPath) async {
    currentNode = PathNode(initialPath ?? await getRootPath());
    loadEntitiesAndNotify();
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
    if (isMultiSelectMode) return false;
    final parentDirectory = Directory(currentNode.path).parent;
    return parentDirectory.existsSync() &&
        parentDirectory.path != currentNode.path;
  }

  bool get canGoBack {
    return currentNode.parent != null && !isMultiSelectMode;
  }

  bool get canGoForward {
    return currentNode.child != null && !isMultiSelectMode;
  }

  Future<void> loadEntitiesAndNotify() async {
    isLoading = true;
    notifyListeners();
    selectedEntities.clear();
    try {
      final directory = Directory(currentNode.path);
      entities = _sortEntities(await directory.list().toList());
      isLoading = false;
      setErrorMessageAndNotify(null);
    } on Exception catch (e) {
      isLoading = false;
      setErrorMessageAndNotify('无法访问该目录: $e');
    }
  }

  List<FileSystemEntity> _sortEntities(List<FileSystemEntity> entities) {
    switch (sortBy) {
      case 'name':
        return entities
          ..sort(
              (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      case 'date':
        return entities
          ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      case 'size':
        try {
          return entities
            ..sort((a, b) {
              if (a is Directory && b is File) return -1;
              if (a is File && b is Directory) return 1;
              if (a is File && b is File) {
                return b.lengthSync().compareTo(a.lengthSync());
              }
              return 0;
            });
        } catch (_) {
          return entities;
        }
      default:
        return entities;
    }
  }

  void changeSortMethod(String method) {
    sortBy = method;
    entities = _sortEntities(entities);
    notifyListeners();
  }

  DateTime _lastPopTime = DateTime(0);

  bool popOrBack() {
    if (canGoBack) {
      goBack();
      return true;
    }
    final now = DateTime.now();
    if (now.difference(_lastPopTime) <= const Duration(seconds: 2)) exit(0);
    _lastPopTime = now;
    return false;
  }

  void openDirectory(String newPath) {
    selectedEntities.clear();
    try {
      if (FileSystemEntity.identicalSync(currentNode.path, newPath)) return;
    } catch (_) {}
    currentNode.setChild(PathNode(newPath));
    goForward();
  }

  void goBack() {
    currentNode = currentNode.parent!;
    loadEntitiesAndNotify();
  }

  void goForward() {
    currentNode = currentNode.child!;
    loadEntitiesAndNotify();
  }

  void goUp() => openDirectory(Directory(currentNode.path).parent.path);

  void toggleItemSelect(FileSystemEntity entity) {
    final existingIndex = selectedEntities
        .indexWhere((e) => FileSystemEntity.identicalSync(e.path, entity.path));
    if (existingIndex != -1) {
      selectedEntities.removeAt(existingIndex);
    } else {
      selectedEntities.add(entity);
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

  void openEntity(FileSystemEntity entity) {
    if (entity is Directory) {
      openDirectory(entity.path);
    } else {
      EntityOperator.openFile(entity.path);
    }
  }

  void onTapItem(FileSystemEntity entity) {
    if (isMultiSelectMode) {
      toggleItemSelect(entity);
    } else if (Platform.isAndroid) {
      openEntity(entity);
    } else {
      const doubleTapDelay = Duration(milliseconds: 300);
      final now = DateTime.now();
      final index = entities.indexOf(entity);
      if (now.difference(_lastTapTime) < doubleTapDelay &&
          index == _lastTapIndex) {
        openEntity(entity);
      } else {
        selectedEntities.clear();
        toggleItemSelect(entity);
        _lastTapTime = now;
        _lastTapIndex = index;
      }
    }
  }
}
