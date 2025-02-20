import 'package:flutter/material.dart';
import 'widgets/file_manager.dart';

void main() {
  runApp(const MyApp());
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
      home: const FileManagerHome(),
    );
  }
}

class FileManagerHome extends StatefulWidget {
  const FileManagerHome({super.key});

  @override
  State<FileManagerHome> createState() => _FileManagerHomeState();
}

class _FileManagerHomeState extends State<FileManagerHome> {
  @override
  Widget build(BuildContext context) {
    return const Filemanager();
  }
}
