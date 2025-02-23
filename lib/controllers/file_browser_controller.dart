// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../models/path_node.dart';
// import '../utils/file_utils.dart';

// class FileBrowserController extends ChangeNotifier {
//   late PathNode _currentNode;
//   List<FileSystemEntity> _files = [];
//   String? _errorMessage;
//   bool _isGridView = false;
//   Offset _tapPosition = Offset.zero;
//   double _itemSize = 100.0;

//   FileBrowserController(String initialPath) {
//     _currentNode = PathNode(initialPath);
//     loadCurrentFiles();
//   }

//   // Getters
//   PathNode get currentNode => _currentNode;
//   List<FileSystemEntity> get files => _files;
//   String? get errorMessage => _errorMessage;
//   bool get isGridView => _isGridView;
//   double get itemSize => _itemSize;
//   bool get canGoBack => _currentNode.parent != null;
//   bool get canGoForward => _currentNode.child != null;
//   String get currentPath => _currentNode.path;

//   void storePosition(TapDownDetails details) {
//     _tapPosition = details.globalPosition;
//   }

//   Offset get tapPosition => _tapPosition;

//   void toggleViewType() {
//     _isGridView = !_isGridView;
//     notifyListeners();
//   }

//   Future<void> loadCurrentFiles() async {
//     try {
//       _errorMessage = null;
//       final directory = Directory(_currentNode.path);
//       if (!await directory.exists()) {
//         throw '目录不存在';
//       }

//       _files = await directory.list().toList();
//       _files.sort((a, b) {
//         if (a is Directory && b is! Directory) return -1;
//         if (a is! Directory && b is Directory) return 1;
//         return a.path.toLowerCase().compareTo(b.path.toLowerCase());
//       });
//       notifyListeners();
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//     }
//   }

//   void openNewDirectory(String path) {
//     _currentNode.setChild(PathNode(path));
//     goForward();
//   }

//   void goBack() {
//     if (!canGoBack) return;
//     _currentNode = _currentNode.parent!;
//     loadCurrentFiles();
//   }

//   void goForward() {
//     if (!canGoForward) return;
//     _currentNode = _currentNode.child!;
//     loadCurrentFiles();
//   }

//   void goUp() {
//     openNewDirectory(Directory(_currentNode.path).parent.path);
//   }

//   Future<void> renameFile(FileSystemEntity entity, String newName) async {
//     try {
//       final path = entity.path;
//       final directory = Directory(path).parent;
//       final newPath = '${directory.path}${Platform.pathSeparator}$newName';
//       await entity.rename(newPath);
//       loadCurrentFiles();
//     } catch (e) {
//       throw '重命名失败: $e';
//     }
//   }

//   Future<void> deleteFile(FileSystemEntity entity) async {
//     try {
//       if (entity is Directory) {
//         await entity.delete(recursive: true);
//       } else {
//         await entity.delete();
//       }
//       loadCurrentFiles();
//     } catch (e) {
//       throw '删除失败: $e';
//     }
//   }

//   Future<Map<String, dynamic>> getFileProperties(FileSystemEntity entity) async {
//     try {
//       final stat = await entity.stat();
//       final properties = <String, dynamic>{
//         '名称': entity.path.split(Platform.pathSeparator).last,
//         '路径': entity.path,
//         '修改时间': stat.modified.toString(),
//         '访问时间': stat.accessed.toString(),
//         '创建时间': stat.changed.toString(),
//       };

//       if (entity is File) {
//         properties['大小'] = '${(await entity.length()) ~/ 1024} KB';
//       }

//       return properties;
//     } catch (e) {
//       throw '获取属性失败: $e';
//     }
//   }

//   Future<void> createDirectory(String folderName) async {
//     if (folderName.isEmpty) return;
//     try {
//       final newPath = '${_currentNode.path}${Platform.pathSeparator}$folderName';
//       await Directory(newPath).create();
//       loadCurrentFiles();
//     } catch (e) {
//       throw '创建文件夹失败: $e';
//     }
//   }
// }