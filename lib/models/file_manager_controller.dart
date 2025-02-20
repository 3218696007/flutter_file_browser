// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';

// import '../widgets/file_list_view.dart';
// import 'path_node.dart';

// class FileManagerController with ChangeNotifier {
//   PathNode? _currentNode;
//   String? _parentPath;

//   String get currentPath => _currentNode?.path ?? '';
//   bool get canGoBack => _currentNode?.parent != null;
//   bool get canGoForward => _currentNode?.child != null;
//   bool get canGoUp => _parentPath != null;

//   void setParentPath(String? path) {
//     _parentPath = path;
//     notifyListeners();
//   }

//   void navigateToPath(BuildContext context, String path) {
//     final newNode = PathNode(path);
//     if (_currentNode != null) {
//       _currentNode!.clearChild();
//       _currentNode!.setChild(newNode);
//     }
//     _currentNode = newNode;
//     notifyListeners();
//   }

//   void goBack(BuildContext context) {
//     if (canGoBack && _currentNode?.parent != null) {
//       _currentNode = _currentNode!.parent;
//       notifyListeners();
//     }
//   }

//   void goForward(BuildContext context) {
//     if (canGoForward && _currentNode?.child != null) {
//       _currentNode = _currentNode!.child;
//       notifyListeners();
//     }
//   }

//   void goUp(BuildContext context) {
//     if (canGoUp && _parentPath != null) {
//       navigateToPath(context, _parentPath!);
//     }
//   }
// }
