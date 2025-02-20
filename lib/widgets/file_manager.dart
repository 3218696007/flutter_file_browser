import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/path_node.dart';
import '../utils/file_opener.dart';
import '../utils/file_utils.dart';
import 'file_icon.dart';

class Filemanager extends StatefulWidget {
  const Filemanager({super.key});

  @override
  State<Filemanager> createState() => _FilemanagerState();
}

class _FilemanagerState extends State<Filemanager> {
  List<FileSystemEntity> _currentFiles = [];
  bool isLoading = true;
  bool isGridView = false;
  String sortBy = 'name';
  String? errorMessage;
  final double _itemSize = 120;
  late PathNode _currentNode;

  Future<String> _getRootPath() async {
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
    final parentDirectory = Directory(_currentNode.path).parent;
    return parentDirectory.existsSync() &&
        parentDirectory.path != _currentNode.path;
  }

  bool get _canGoBack => _currentNode.parent != null;

  bool get canGoForward => _currentNode.child != null;

  Offset _tapPosition = Offset.zero;

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  @override
  void initState() {
    _getRootPath().then((rootPath) {
      _currentNode = PathNode(rootPath);
      _loadCurrentFiles();
    });
    super.initState();
  }

  Future<void> _loadCurrentFiles() async {
    setState(() {
      isLoading = true;
    });
    try {
      final directory = Directory(_currentNode.path);
      final entities = await directory.list().toList();
      setState(() {
        _currentFiles = _sortFiles(entities);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('无法访问该目录: $e');
      setState(() {
        isLoading = false;
        errorMessage = '无法访问该目录，可能是因为权限不足。\n请尝试访问其他目录或检查应用权限设置。';
      });
    }
  }

  void _handleFileTap(BuildContext context, FileSystemEntity entity) {
    if (entity is Directory) {
      _openNewDirectory(entity.path);
      _loadCurrentFiles();
    } else {
      FileOpener.openFile(context, entity.path);
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
      _currentFiles = _sortFiles(_currentFiles);
    });
  }

  void toggleViewType() {
    setState(() {
      isGridView = !isGridView;
    });
  }

  DateTime _lastPopTime = DateTime(0);

  _onPopInvoked(_) {
    if (_canGoBack) {
      _goBack();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastPopTime) <= const Duration(seconds: 2)) exit(0);
    _lastPopTime = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('再按一次返回键退出应用'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 0,
          leading: const SizedBox(),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _canGoBack ? _goBack : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: canGoForward ? _goForward : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: canGoUp ? _goUp : null,
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _currentNode.path),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) => _openNewDirectory(value),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: changeSortMethod,
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'name',
                    child: Text('名称'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'date',
                    child: Text('日期'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'size',
                    child: Text('大小'),
                  ),
                ];
              },
            ),
            IconButton(
              icon: Icon(isGridView ? Icons.list : Icons.grid_view),
              onPressed: toggleViewType,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCurrentFiles,
            ),
          ],
        ),
        body: Listener(
          onPointerDown: (event) {
            if (event.buttons == 8 && _canGoBack) _goBack();
            if (event.buttons == 16 && canGoForward) _goForward();
          },
          child: _filesBuilder(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createDirectory,
          child: const Icon(Icons.create_new_folder),
        ),
      ),
    );
  }

  Widget _filesBuilder() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentFiles,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _itemSize,
              mainAxisExtent: _itemSize,
              childAspectRatio: 1,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: _currentFiles.length,
            itemBuilder: (context, index) {
              final entity = _currentFiles[index];
              return _buildGridItem(context, entity);
            },
          )
        : ListView.builder(
            itemCount: _currentFiles.length,
            itemBuilder: (context, index) {
              final entity = _currentFiles[index];
              return _buildListItem(context, entity);
            },
          );
  }

  Widget _buildGridItem(BuildContext context, FileSystemEntity entity) {
    return InkWell(
      onTapDown: _storePosition,
      onTap: () => _handleFileTap(context, entity),
      onLongPress: () => _showFileOperationMenu(context, entity),
      onSecondaryTapDown: _storePosition,
      onSecondaryTap: () => _showFileOperationMenu(context, entity),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FileIconWidget(entity: entity, size: 0.5 * _itemSize),
          Text(
            FileUtils.getFileName(entity),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, FileSystemEntity entity) {
    return GestureDetector(
      onTapDown: _storePosition,
      onSecondaryTapDown: _storePosition,
      onSecondaryTap: () => _showFileOperationMenu(context, entity),
      child: ListTile(
        minTileHeight: 0.4 * _itemSize,
        leading: FileIconWidget(entity: entity, size: 0.3 * _itemSize),
        title: Text(FileUtils.getFileName(entity)),
        onTap: () => _handleFileTap(context, entity),
        onLongPress: () => _showFileOperationMenu(context, entity),
      ),
    );
  }

  void _openNewDirectory(String path) {
    _currentNode.setChild(PathNode(path));
    _goForward();
  }

  void _goBack() {
    _currentNode = _currentNode.parent!;
    _loadCurrentFiles();
  }

  void _goForward() {
    _currentNode = _currentNode.child!;
    _loadCurrentFiles();
  }

  void _goUp() => _openNewDirectory(Directory(_currentNode.path).parent.path);

  Future<void> renameFile(FileSystemEntity entity, String newName) async {
    try {
      final path = entity.path;
      final directory = Directory(path).parent;
      final newPath = '${directory.path}${Platform.pathSeparator}$newName';
      await entity.rename(newPath);
      _loadCurrentFiles();
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
      _loadCurrentFiles();
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

  Future<void> _showFileOperationMenu(
    BuildContext context,
    FileSystemEntity entity,
  ) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
        _tapPosition & const Size(40, 40), Offset.zero & overlay.size);
    final result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new),
              SizedBox(width: 8),
              Text('打开'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.drive_file_rename_outline),
              SizedBox(width: 8),
              Text('重命名'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.content_copy),
              SizedBox(width: 8),
              Text('复制'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cut',
          child: Row(
            children: [
              Icon(Icons.content_cut),
              SizedBox(width: 8),
              Text('剪切'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.content_paste),
              SizedBox(width: 8),
              Text('粘贴'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'properties',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('属性'),
            ],
          ),
        ),
      ],
    );

    if (result == null) return;

    if (!context.mounted) return;

    switch (result) {
      case 'open':
        _handleFileTap(context, entity);
        break;
      case 'rename':
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            String name = FileUtils.getFileName(entity);
            return AlertDialog(
              title: const Text('重命名'),
              content: TextField(
                autofocus: true,
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
                decoration: const InputDecoration(
                  labelText: '新名称',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, name),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.isNotEmpty && context.mounted) {
          try {
            await renameFile(entity, newName);
            _loadCurrentFiles();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text('确定要删除 ${FileUtils.getFileName(entity)} 吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );

        if (confirm == true && context.mounted) {
          try {
            await deleteFile(entity);
            _loadCurrentFiles();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        }
        break;
      case 'properties':
        final properties = await getFileProperties(entity);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(FileUtils.getFileName(entity)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: properties.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        }
        break;
    }
  }

  void _createDirectory() async {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, newFolderName),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (folderName != null && folderName.isNotEmpty) {
      final newPath = '${_currentNode.path}/$folderName';
      await Directory(newPath).create();
      _loadCurrentFiles();
    }
  }
}
