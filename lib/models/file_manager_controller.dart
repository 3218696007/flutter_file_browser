import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/file_list_view.dart';
import 'path_node.dart';

class FileManagerController with ChangeNotifier {
  PathNode? _currentNode;

  String get currentPath => _currentNode?.path ?? '';
  bool get canGoBack => _currentNode?.parent != null;
  bool get canGoForward => _currentNode?.child != null;
  bool get canGoUp => _parentPath != null;
  String? _parentPath;

  void navigateToPath(
    BuildContext context,
    String path, {
    bool updateHistory = true,
  }) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WillPopScope(
            onWillPop: () async {
              if (canGoBack) {
                goBack(context);
                return false;
              }
              return true;
            },
            child: FileListView(path),
          ),
        ),
      );
      final parentDirectory = Directory(path).parent;
      parentDirectory.exists().then((result) {
        if (result && parentDirectory.path != path) {
          _parentPath = parentDirectory.path;
        } else {
          _parentPath = null;
        }
        notifyListeners();
      });
      if (updateHistory) {
        final newNode = PathNode(path);
        if (_currentNode != null) {
          _currentNode!.clearChild();
          _currentNode!.setChild(newNode);
        }
        _currentNode = newNode;
      }
    } catch (e) {
      debugPrint('导航失败: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> goBack(BuildContext context) async {
    if (canGoBack && _currentNode?.parent != null) {
      _currentNode = _currentNode!.parent;
      navigateToPath(context, _currentNode!.path, updateHistory: false);
    }
  }

  Future<void> goForward(BuildContext context) async {
    if (canGoForward && _currentNode?.child != null) {
      _currentNode = _currentNode!.child;
      navigateToPath(context, _currentNode!.path, updateHistory: false);
    }
  }

  void goUp(BuildContext context) {
    navigateToPath(context, _parentPath!);
  }

  Future init() async {
    await requestPermissionAndLoadInitialPath();
  }

  Future<void> requestPermissionAndLoadInitialPath() async {
    try {
      bool hasPermission = false;

      if (Platform.isAndroid) {
        // 先尝试请求MANAGE_EXTERNAL_STORAGE权限
        if (await Permission.manageExternalStorage.request().isGranted) {
          hasPermission = true;
        } else {
          // 如果失败，尝试请求普通存储权限
          hasPermission = await Permission.storage.request().isGranted;
        }
      } else {
        // 非Android平台直接请求存储权限
        hasPermission = await Permission.storage.request().isGranted;
      }

      if (hasPermission) {
        String initialPath;
        if (Platform.isAndroid) {
          final directory = await getExternalStorageDirectory();
          initialPath = directory?.path.split('Android')[0] ?? '/';
        } else if (Platform.isWindows) {
          initialPath = 'C:\\';
        } else {
          initialPath = '/';
        }
        _currentNode = PathNode(initialPath);
      } else {
        debugPrint('存储权限被拒绝');
      }
    } catch (e) {
      debugPrint('初始化失败: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> renameFile(FileSystemEntity entity, String newName) async {
    try {
      final path = entity.path;
      final directory = Directory(path).parent;
      final newPath = '${directory.path}${Platform.pathSeparator}$newName';
      await entity.rename(newPath);
      notifyListeners();
    } catch (e) {
      throw '重命名失败: $e';
    }
  }

  Future<void> deleteFile(FileSystemEntity entity) async {
    try {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else {
        await entity.delete();
      }
      notifyListeners();
    } catch (e) {
      throw '删除失败: $e';
    }
  }

  Future<Map<String, dynamic>> getFileProperties(
      FileSystemEntity entity) async {
    try {
      final stat = await entity.stat();
      final properties = <String, dynamic>{
        '名称': entity.path.split(Platform.pathSeparator).last,
        '路径': entity.path,
        '类型': entity is Directory ? '文件夹' : '文件',
        '修改时间': stat.modified.toString(),
        '访问时间': stat.accessed.toString(),
        '创建时间': stat.changed.toString(),
      };

      if (entity is File) {
        properties['大小'] = '${(await entity.length()) ~/ 1024} KB';
      }

      return properties;
    } catch (e) {
      throw '获取属性失败: $e';
    }
  }

  openFile(String path) {
    // TODO: 打开文件
  }
}
