import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/file_browser_controller.dart';
import '../../service/file_opener.dart';
import '../../service/entity_utils.dart';
import 'file_icon.dart';

class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final _controller = FileBrowserController();
  final double _itemSize = 120;
  DateTime _lastTapTime = DateTime(0);
  int _lastTapIndex = -1;
  Offset _tapPosition = Offset.zero;

  void _storePosition(TapDownDetails details) =>
      _tapPosition = details.globalPosition;

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
      builder: (context, __) {
        if (_controller.isLoading) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return PopScope(
          canPop: false,
          onPopInvoked: _onPopInvoked,
          child: CallbackShortcuts(
            bindings: _controller.shortcutbindings,
            child: Listener(
              onPointerDown: _controller.isMultiSelectMode
                  ? null
                  : (event) {
                      if (event.buttons == 8 && _controller.canGoBack) {
                        _controller.goBack();
                      }
                      if (event.buttons == 16 && _controller.canGoForward) {
                        _controller.goForward();
                      }
                    },
              child: Focus(
                autofocus: true,
                child: Scaffold(
                  appBar: AppBar(
                    leadingWidth: 0,
                    leading: const SizedBox(),
                    title: _barLeadingButtons(),
                    actions: _barActions(),
                    bottom: _breadcrumbNavBar(),
                  ),
                  body: _filesView(),
                  // floatingActionButton:  _createItemButton(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _barLeadingButtons() {
    if (_controller.isMultiSelectMode) {
      return Row(
        children: [
          TextButton(
            onPressed: _controller.cancelMultiSelect,
            child: const Text('退出多选'),
          ),
        ],
      );
    }
    return Row(children: [
      Tooltip(
        message: '后退\n鼠标回退侧键',
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _controller.canGoBack ? _controller.goBack : null,
        ),
      ),
      Tooltip(
        message: '前进\n鼠标前进侧键',
        child: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _controller.canGoForward ? _controller.goForward : null,
        ),
      ),
      IconButton(
        tooltip: '向上',
        icon: const Icon(Icons.arrow_upward),
        onPressed: _controller.canGoUp ? _controller.goUp : null,
      ),
      Tooltip(
        message: '刷新',
        child: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _controller.loadCurrentFiles,
          // onPressed: controller.loadCurrentFiles,
        ),
      ),
      TextButton(
        onPressed: _controller.enterMultiSelectMode,
        child: const Text('多选', style: TextStyle(color: Colors.black)),
      ),
    ]);
  }

  List<Widget> _barActions() {
    return [
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
      Tooltip(
        message: '切换视图',
        child: IconButton(
          icon: Icon(_controller.isListView ? Icons.grid_view : Icons.list),
          onPressed: _controller.toggleView,
        ),
      ),
    ];
  }

  PreferredSize _breadcrumbNavBar() {
    if (_controller.isMultiSelectMode) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(10),
        child: Text(
          '多选模式：禁用其它功能；点击切换选中状态；点击两个右上角连续切换选中状态',
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      );
    }
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _breadcrumbsBuilder(),
              ),
            ),
            Tooltip(
              message: '跳转到',
              child: IconButton(
                  onPressed: _showJumpToDialog,
                  icon: const Icon(Icons.edit_outlined)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _breadcrumbsBuilder() {
    final List<Widget> widgets = [];
    final parts = _controller.currentNode.path.split(Platform.pathSeparator);
    String currentPath = '';
    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (part.isEmpty) continue;
      currentPath = Platform.isWindows
          ? '$currentPath$part${Platform.pathSeparator}'
          : '$currentPath$part/';
      widgets.add(_breadcrumbButton(parts[i], currentPath));
      widgets.add(const Icon(Icons.chevron_right, size: 20));
    }
    return widgets;
  }

  Widget _breadcrumbButton(String label, String path) {
    return TextButton(
      onPressed: () => _controller.openDirectory(path),
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  void _showJumpToDialog() async {
    String pathWillJumpTo = _controller.currentNode.path;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final pathController = TextEditingController(
          text: _controller.currentNode.path,
        );
        // 自动全选路径
        pathController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: pathController.text.length,
        );
        return AlertDialog(
          title: const Text('跳转到'),
          content: TextField(
            autofocus: true,
            controller: pathController,
            onChanged: (value) => pathWillJumpTo = value,
            onSubmitted: (_) => Navigator.pop(context),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
    _controller.openDirectory(pathWillJumpTo);
  }

  Widget _filesView() {
    if (_controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            Text(_controller.errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (_controller.currentFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            Text('这里什么都没有', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (_controller.isListView) {
      return ListView.builder(
        key: PageStorageKey(_controller.currentNode),
        itemCount: _controller.currentFiles.length,
        itemBuilder: (context, index) {
          final entity = _controller.currentFiles[index];
          return _itemBuilder(
            index,
            itemView: ListTile(
              minTileHeight: 0.4 * _itemSize,
              leading: FileIcon(entity: entity, size: 0.3 * _itemSize),
              title: Text(entity.name),
            ),
          );
        },
      );
    }
    // else is grid view
    return GridView.builder(
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
        return _itemBuilder(
          index,
          itemView: GridTile(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FileIcon(entity: entity, size: 0.5 * _itemSize),
                Text(
                  entity.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemBuilder(int index, {required Widget itemView}) {
    final entity = _controller.currentFiles[index];
    return Ink(
      color: _controller.selectedItems.contains(entity)
          ? Colors.blueGrey[200]
          : null,
      child: InkWell(
        onTap: () => _onTapItem(entity),
        onTapDown: _storePosition,
        onLongPress: () => _showOperationMenu(entity),
        onSecondaryTapDown: _storePosition,
        onSecondaryTap: () => _showOperationMenu(entity),
        child: Stack(
          alignment: Alignment.center,
          children: [
            itemView,
            if (_controller.isMultiSelectMode)
              Positioned(
                top: 0.1 * _itemSize,
                right: 0.1 * _itemSize,
                child: InkWell(
                  onTap: () => _controller.consecutiveSelecte(index),
                  child: Icon(
                    Icons.linear_scale,
                    color: _controller.indexStartedSelected == index
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTapItem(FileSystemEntity entity) {
    if (_controller.isMultiSelectMode) {
      _controller.toggleItemSelect(entity);
    } else if (Platform.isAndroid) {
      _openItem(entity);
    } else {
      const doubleTapDelay = Duration(milliseconds: 300);
      final now = DateTime.now();
      final index = _controller.currentFiles.indexOf(entity);
      if (now.difference(_lastTapTime) < doubleTapDelay &&
          index == _lastTapIndex) {
        _openItem(entity);
      } else {
        _controller.cancelMultiSelect();
        _controller.toggleItemSelect(entity);
        _lastTapTime = now;
        _lastTapIndex = index;
      }
    }
  }

  Future<void> _showOperationMenu(FileSystemEntity entity) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      _tapPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );
    final result = await showMenu<EntityOperation>(
      context: context,
      position: position,
      items: EntityOperation.values.map((operation) {
        return PopupMenuItem(
          value: operation,
          child: Row(
            children: [
              operation.icon,
              const SizedBox(width: 8),
              Text(
                operation.label,
                style: TextStyle(
                  color:
                      operation == EntityOperation.delete ? Colors.red : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
    if (result != null && mounted) {
      await _handleOperation(result, entity, context);
    }
  }

  Future<void> _handleOperation(
    EntityOperation operation,
    FileSystemEntity entity,
    BuildContext context,
  ) async {
    switch (operation) {
      case EntityOperation.open:
        _openItem(entity);
        break;
      case EntityOperation.rename:
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            String name = entity.name;
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
      case EntityOperation.delete:
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text('确定要删除 ${entity.name} 吗？'),
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
      case EntityOperation.properties:
        final properties = _controller.getFileProperties(entity);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(entity.name),
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
      case EntityOperation.cut:
      case EntityOperation.copy:
      case EntityOperation.paste:
        // TODO: 实现剪切、复制、粘贴功能
        break;
    }
  }

  void _openItem(FileSystemEntity entity) {
    if (entity is Directory) {
      _controller.openDirectory(entity.path);
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

// Widget _createItemButton() {
//   return FloatingActionButton(
//     onPressed: () {
//       showDialog<String>(
//         context: context,
//         builder: (BuildContext context) {
//           final name = ValueNotifier('');
//           return AlertDialog(
//             title: const Text('创建新文件夹'),
//             content: TextField(
//               autofocus: true,
//               onChanged: (value) => name.value = value,
//               decoration: const InputDecoration(
//                 hintText: '请输入文件夹名称',
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('取消'),
//               ),
//               ValueListenableBuilder(
//                 valueListenable: name,
//                 builder: (_, value, __) {
//                   return TextButton(
//                     onPressed: value.isEmpty
//                         ? null
//                         : () {
//                       Navigator.pop(context);
//                       _controller
//                           .createDirectory(value)
//                           .then((message) {
//                         ScaffoldMessenger.of(context)
//                             .showSnackBar(
//                           SnackBar(
//                             content: Text(message),
//                           ),
//                         );
//                       });
//                     },
//                     child: const Text('确定'),
//                   );
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     },
//     child: const Icon(Icons.create_new_folder),
//   );
// }
}
