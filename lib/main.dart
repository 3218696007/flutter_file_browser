import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/file_manager_controller.dart';
import 'widgets/file_list_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileManagerController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '文件管理器',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const FileManagerHome(),
      ),
    );
  }
}

class FileManagerHome extends StatefulWidget {
  const FileManagerHome({super.key});

  @override
  State<FileManagerHome> createState() => _FileManagerHomeState();
}

class _FileManagerHomeState extends State<FileManagerHome> {
  bool _isLoading = true;
  late final FileManagerController _controller;

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    _controller = Provider.of<FileManagerController>(context, listen: false);
    _controller.init().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    return FileListView(_controller.currentPath);
  }
}
