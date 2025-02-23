import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/file_browser_controller.dart';
import '../utils/file_opener.dart';
import '../utils/file_utils.dart';
import 'file_icon.dart';

class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final _controller = FileBrowserController();
  bool _isGridView = false;
  final double _itemSize = 120;

  Offset _tapPosition = Offset.zero;

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  @override
  void initState() {
    _controller.initialize(widget.initialPath);
    super.initState();
  }

  _onPopInvoked(_) {
    if (_controller.cantPopOrBack()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次返回键退出应用'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        if (_controller.isLoading) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
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
                    onPressed:
                        _controller.canGoBack ? _controller.goBack : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed:
                        _controller.canGoForward ? _controller.goForward : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _controller.canGoUp ? _controller.goUp : null,
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.folder_outlined),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _buildBreadcrumbs(),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              final controller = TextEditingController(
                                text: _controller.currentNode.path,
                              );
                              // 自动全选路径
                              controller.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: controller.text.length,
                              );
                              return AlertDialog(
                                title: const Text('跳转到'),
                                content: TextField(
                                  autofocus: true,
                                  controller: controller,
                                  onSubmitted: (value) {
                                    final directory = Directory(value);
                                    if (directory.existsSync()) {
                                      _controller.openNewDirectory(value);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('目录不存在'),
                                        ),
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  tooltip: '排序',
                  icon: const Icon(Icons.sort_by_alpha),
                  onSelected: _controller.changeSortMethod,
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
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _controller.loadCurrentFiles,
                  // onPressed: _controller.loadCurrentFiles,
                ),
              ],
            ),
            body: Listener(
              onPointerDown: (event) {
                if (event.buttons == 8 && _controller.canGoBack) {
                  _controller.goBack();
                }
                if (event.buttons == 16 && _controller.canGoForward) {
                  _controller.goForward();
                }
              },
              child: _filesBuilder(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    final name = ValueNotifier('');
                    return AlertDialog(
                      title: const Text('创建新文件夹'),
                      content: TextField(
                        autofocus: true,
                        onChanged: (value) => name.value = value,
                        decoration: const InputDecoration(
                          hintText: '请输入文件夹名称',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        ValueListenableBuilder(
                          valueListenable: name,
                          builder: (_, value, __) {
                            return TextButton(
                              onPressed: value.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _controller
                                          .createDirectory(value)
                                          .then((message) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                          ),
                                        );
                                      });
                                    },
                              child: const Text('确定'),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.create_new_folder),
            ),
          ),
        );
      },
    );
  }

  Widget _filesBuilder() {
    if (_controller.errorMessage != null) {
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
              _controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.loadCurrentFiles,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return _isGridView
        ? GridView.builder(
            key: PageStorageKey(_controller.currentNode),
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _itemSize,
              mainAxisExtent: _itemSize,
              childAspectRatio: 1,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: _controller.currentFiles.length,
            itemBuilder: (context, index) {
              final entity = _controller.currentFiles[index];
              return _buildGridItem(context, entity);
            },
          )
        : ListView.builder(
            key: PageStorageKey(_controller.currentNode),
            itemCount: _controller.currentFiles.length,
            itemBuilder: (context, index) {
              final entity = _controller.currentFiles[index];
              return _buildListItem(context, entity);
            },
          );
  }

  Widget _buildGridItem(BuildContext context, FileSystemEntity entity) {
    return Ink(
      color: _controller.selectedItems.contains(entity)
          ? Colors.blueGrey[200]
          : null,
      child: InkWell(
        onTapDown: _storePosition,
        onTap: () => _onTapItem(entity),
        onLongPress: () => _onLongTapItem(entity),
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
      ),
    );
  }

  DateTime _lastTapTime = DateTime(0);
  int _lastTapIndex = -1;

  void _onTapItem(FileSystemEntity entity) {
    if (Platform.isAndroid) {
      _openItem(entity);
      return;
    }
    const doubleTapDelay = Duration(milliseconds: 300);
    final now = DateTime.now();
    final index = _controller.currentFiles.indexOf(entity);
    if (now.difference(_lastTapTime) < doubleTapDelay &&
        index == _lastTapIndex) {
      _openItem(entity);
    } else {
      _controller.switchItem(entity);
      _lastTapTime = now;
      _lastTapIndex = index;
    }
  }

  Widget _buildListItem(BuildContext context, FileSystemEntity entity) {
    return Ink(
      color: _controller.selectedItems.contains(entity)
          ? Colors.blueGrey[200]
          : null,
      child: InkWell(
        onTap: () => _onTapItem(entity),
        onTapDown: _storePosition,
        onLongPress: () => _onLongTapItem(entity),
        onSecondaryTapDown: _storePosition,
        onSecondaryTap: () => _showFileOperationMenu(context, entity),
        child: ListTile(
          minTileHeight: 0.4 * _itemSize,
          leading: FileIconWidget(entity: entity, size: 0.3 * _itemSize),
          title: Text(FileUtils.getFileName(entity)),
        ),
      ),
    );
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
        _openItem(entity);
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

        _controller.renameFile(entity, newName).then((message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        });
        break;
      case 'delete':
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text('确定要删除 ${FileUtils.getFileName(entity)} 吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    _controller.deleteFile(entity).then((message) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
        break;
      case 'properties':
        final properties = _controller.getFileProperties(entity);

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
        break;
    }
  }

  List<Widget> _buildBreadcrumbs() {
    final List<Widget> widgets = [];
    final parts = _controller.currentNode.path.split(Platform.pathSeparator);
    String currentPath = '';

    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (part.isEmpty) continue;
      currentPath = Platform.isWindows
          ? '$currentPath$part${Platform.pathSeparator}'
          : '$currentPath$part/';
      widgets.add(_buildBreadcrumbItem(parts[i], currentPath));
      widgets.add(const Icon(Icons.chevron_right, size: 20));
    }

    return widgets;
  }

  Widget _buildBreadcrumbItem(String label, String path) {
    return TextButton(
      onPressed: () => _controller.openNewDirectory(path),
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  void _openItem(FileSystemEntity entity) {
    if (entity is Directory) {
      _controller.openNewDirectory(entity.path);
    } else {
      FileOpener.openFile(entity.path).then((error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
            ),
          );
        }
      });
    }
  }

  _onLongTapItem(FileSystemEntity entity) {
    _showFileOperationMenu(context, entity);
    _controller.switchItem(entity);
  }
}
