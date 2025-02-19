import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_manager_controller.dart';
import 'file_list_item.dart';

class FileListView extends StatefulWidget {
  const FileListView(this.path, {super.key});

  final String path;

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  List<FileSystemEntity> files = [];
  bool isLoading = false;
  bool isGridView = false;
  String sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final directory = Directory(widget.path);
      final entities = await directory.list().toList();
      setState(() {
        files = _sortFiles(entities);
      });
    } catch (e) {
      debugPrint('加载文件失败: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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
    setState(() {
      sortBy = method;
      files = _sortFiles(files);
    });
  }

  void toggleViewType() {
    setState(() {
      isGridView = !isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FileManagerController>(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox(),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.canGoBack
                  ? () => controller.goBack(context)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: controller.canGoForward
                  ? () => controller.goForward(context)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed:
                  controller.canGoUp ? () => controller.goUp(context) : null,
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: widget.path),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (value) =>
                    controller.navigateToPath(context, value),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(sortBy == 'name'
                ? Icons.sort_by_alpha
                : sortBy == 'date'
                    ? Icons.access_time
                    : Icons.file_copy),
            onSelected: changeSortMethod,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha,
                        color: sortBy == 'name'
                            ? Theme.of(context).primaryColor
                            : null),
                    const SizedBox(width: 8),
                    const Text('按名称'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: sortBy == 'date'
                            ? Theme.of(context).primaryColor
                            : null),
                    const SizedBox(width: 8),
                    const Text('按日期'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'size',
                child: Row(
                  children: [
                    Icon(Icons.file_copy,
                        color: sortBy == 'size'
                            ? Theme.of(context).primaryColor
                            : null),
                    const SizedBox(width: 8),
                    const Text('按大小'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: toggleViewType,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final entity = files[index];
                    return FileListItem(
                      entity: entity,
                      isGridView: true,
                      onTap: entity is Directory
                          ? () =>
                              controller.navigateToPath(context, entity.path)
                          : () => controller.openFile(entity.path),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final entity = files[index];
                    return FileListItem(
                      entity: entity,
                      onTap: entity is Directory
                          ? () =>
                              controller.navigateToPath(context, entity.path)
                          : () => controller.openFile(entity.path),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? folderName = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              String newFolderName = '';
              return AlertDialog(
                title: const Text('创建新文件夹'),
                content: TextField(
                  autofocus: true,
                  onChanged: (value) => newFolderName = value,
                  decoration: const InputDecoration(
                    hintText: '请输入文件夹名称',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, newFolderName),
                    child: const Text('确定'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              );
            },
          );
          if (folderName != null && folderName.isNotEmpty) {
            final newPath = '${Directory(widget.path).path}/$folderName';
            await Directory(newPath).create();
            _loadFiles();
          }
        },
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
