import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/file_browser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestStoragePermission();
  runApp(const MyApp());
}

Future<void> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '文件管理器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FileBrowser(),
    );
  }
}
