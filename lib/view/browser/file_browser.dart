import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/browser_clipboard.dart';
import '../../controller/file_browser_controller.dart';
import '../../service/entity_extension.dart';
import '../../service/entity_operator.dart';
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
  Offset _tapPosition = Offset.zero;

  void _storePosition(TapDownDetails details) =>
      _tapPosition = details.globalPosition;

  @override
  void initState() {
    _controller.initialize(widget.initialPath);
    super.initState();
  }

  _onPopInvoked(_) {
    if (_controller.isMultiSelectMode) return;
    if (!_controller.popOrBack()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次返回键退出应用'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Map<ShortcutActivator, VoidCallback> get _shortcutbindings => {
        const SingleActivator(LogicalKeyboardKey.f5):
            _controller.loadEntitiesAndNotify,
        const SingleActivator(alt: true, LogicalKeyboardKey.arrowLeft): () {
          if (_controller.canGoBack) _controller.goBack();
        },
        const SingleActivator(alt: true, LogicalKeyboardKey.arrowRight): () {
          if (_controller.canGoForward) _controller.goForward();
        },
        const SingleActivator(alt: true, LogicalKeyboardKey.arrowUp): () {
          if (_controller.canGoUp) _controller.goUp();
        },
        const SingleActivator(alt: true, LogicalKeyboardKey.keyV):
            _controller.toggleView,
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            _deleteSelectedItems,
      };

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
            bindings: _shortcutbindings,
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
                    bottom: _controller.isMultiSelectMode
                        ? const PreferredSize(
                            preferredSize: Size.fromHeight(48),
                            child: Text(
                              '多选模式：禁用其它功能，点击切换选中\n如何连选：依次点击起点和终点的连选图标',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                          )
                        : _breadcrumbNavBar(),
                  ),
                  body: _filesView(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _barLeadingButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _controller.isMultiSelectMode
            ? [
                TextButton(
                  onPressed: _controller.cancelMultiSelect,
                  child: const Text('退出多选'),
                ),
              ]
            : [
                Tooltip(
                  message: '后退\n鼠标回退侧键',
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed:
                        _controller.canGoBack ? _controller.goBack : null,
                  ),
                ),
                Tooltip(
                  message: '前进\n鼠标前进侧键',
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed:
                        _controller.canGoForward ? _controller.goForward : null,
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
                    onPressed: _controller.loadEntitiesAndNotify,
                    // onPressed: controller.loadCurrentFiles,
                  ),
                ),
                TextButton(
                  onPressed: _controller.enterMultiSelectMode,
                  child:
                      const Text('多选', style: TextStyle(color: Colors.black)),
                ),
              ],
      ),
    );
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
                  onPressed: _jumpToPath,
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

  void _jumpToPath() async {
    final pathWillJump = ValueNotifier(_controller.currentNode.path);
    await _showValueInputDialog('跳转到', updataValue: pathWillJump);
    if (Directory(pathWillJump.value).existsSync()) {
      _controller.openDirectory(pathWillJump.value);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('目录不存在'),
        ),
      );
    }
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
    return GestureDetector(
      onSecondaryTap:
          _controller.isMultiSelectMode ? null : _showNoEntityOperationMenu,
      onSecondaryTapDown: _storePosition,
      onLongPress:
          _controller.isMultiSelectMode ? null : _showNoEntityOperationMenu,
      onTapDown: _storePosition,
      child: Builder(builder: (context) {
        if (_controller.currentEntities.isEmpty) {
          return Container(
            alignment: Alignment.center,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Column(
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
            itemCount: _controller.currentEntities.length,
            itemExtent: 0.4 * _itemSize,
            itemBuilder: (context, index) {
              final entity = _controller.currentEntities[index];
              return _itemBuilder(
                index,
                itemView: ListTile(
                  minTileHeight: 0.4 * _itemSize,
                  leading: FileIcon(entity: entity, size: 0.3 * _itemSize),
                  title: Text(
                    entity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: _controller.currentEntities.length,
          itemBuilder: (context, index) {
            final entity = _controller.currentEntities[index];
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
      }),
    );
  }

  Widget _itemBuilder(int index, {required Widget itemView}) {
    final entity = _controller.currentEntities[index];
    return Ink(
      color: _controller.selectedEntities.contains(entity)
          ? Colors.blueGrey[200]
          : null,
      child: InkWell(
        onTap: () => _controller.onTapItem(entity),
        onTapDown: _storePosition,
        onLongPress: () => _showEntityOperationMenu(entity),
        onSecondaryTapDown: _storePosition,
        onSecondaryTap: () => _showEntityOperationMenu(entity),
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

  List<PopupMenuEntry<EntityOperation>> get _entityOperationMenuItems {
    if (!_controller.isMultiSelectMode) {
      return EntityOperation.values.map((operation) {
        return PopupMenuItem(
          value: operation,
          child: Row(
            children: [
              operation.icon,
              const SizedBox(width: 8),
              operation.label
            ],
          ),
        );
      }).toList();
    }
    return [
      // 剪切 复制 粘贴
      PopupMenuItem(
        value: EntityOperation.cut,
        child: Row(
          children: [
            EntityOperation.cut.icon,
            const SizedBox(width: 8),
            EntityOperation.cut.label
          ],
        ),
      ),
      PopupMenuItem(
        value: EntityOperation.copy,
        child: Row(
          children: [
            EntityOperation.copy.icon,
            const SizedBox(width: 8),
            EntityOperation.copy.label
          ],
        ),
      ),
      PopupMenuItem(
        value: EntityOperation.delete,
        child: Row(
          children: [
            EntityOperation.delete.icon,
            const SizedBox(width: 8),
            EntityOperation.delete.label
          ],
        ),
      ),
    ];
  }

  Future<void> _showEntityOperationMenu(FileSystemEntity entity) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      _tapPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );
    if (!_controller.isMultiSelectMode) {
      _controller.selectedEntities.clear();
      _controller.toggleItemSelect(entity);
    }
    final result = await showMenu<EntityOperation>(
      context: context,
      position: position,
      items: _entityOperationMenuItems,
    );
    if (result != null && mounted) {
      await _handleEntityOperation(result, entity);
    }
  }

  Future<void> _showNoEntityOperationMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      _tapPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );
    final result = await showMenu<NoEntityOperation>(
      context: context,
      position: position,
      items: NoEntityOperation.values.map((operation) {
        return PopupMenuItem(
          value: operation,
          child: Row(
            children: [
              operation.icon,
              const SizedBox(width: 8),
              Text(operation.label),
            ],
          ),
        );
      }).toList(),
    );
    if (result != null && mounted) {
      await _handleEmptyEntityOperation(result, context);
    }
  }

  Future<void> _handleEmptyEntityOperation(
    NoEntityOperation operation,
    BuildContext context,
  ) async {
    switch (operation) {
      case NoEntityOperation.create:
        _createDirectory();
        break;
      case NoEntityOperation.refresh:
        _controller.loadEntitiesAndNotify();
        break;
      case NoEntityOperation.paste:
        _pasteEntities();
        break;
    }
  }

  Future<bool?> _showValueInputDialog(
    String title, {
    required ValueNotifier updataValue,
  }) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: updataValue.value);
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            controller: controller,
            onChanged: (value) => updataValue.value = value,
            onSubmitted: (_) => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleEntityOperation(
    EntityOperation operation,
    FileSystemEntity entity,
  ) async {
    switch (operation) {
      case EntityOperation.open:
        _controller.openEntity(entity);
        break;
      case EntityOperation.refresh:
        _controller.loadEntitiesAndNotify();
        break;
      case EntityOperation.rename:
        _renameEntity(entity);
        break;
      case EntityOperation.create:
        _createDirectory();
        break;
      case EntityOperation.delete:
        _deleteSelectedItems();
        break;
      case EntityOperation.property:
        _showPropertiesDialog(entity);
        break;
      case EntityOperation.cut:
        _copyToClipboard(fromCut: true);
        break;
      case EntityOperation.copy:
        _copyToClipboard();
        break;
      case EntityOperation.paste:
        _pasteEntities();
        break;
    }
  }

  void _copyToClipboard({bool fromCut = false}) {
    BrowserClipboard.copy(_controller.selectedEntities, fromCut: fromCut);
  }

  Future<void> _createDirectory() async {
    final directoryName = ValueNotifier('新建文件夹');
    final cancel =
        await _showValueInputDialog('新建文件夹', updataValue: directoryName);
    if (directoryName.value.isNotEmpty && cancel != true) {
      EntityOperator.createDirectory(
        directoryName.value,
        path: _controller.currentNode.path,
      ).then((message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
        _controller.loadEntitiesAndNotify();
      });
    }
  }

  Future<void> _renameEntity(FileSystemEntity entity) async {
    final newName = ValueNotifier(entity.name);
    await _showValueInputDialog('重命名', updataValue: newName);
    if (newName.value == entity.name || newName.value.isEmpty) return;
    EntityOperator.rename(entity, newName.value).then((message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
      _controller.loadEntitiesAndNotify();
    });
  }

  void _showConfirmDialog(String content, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: onConfirm,
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showPropertiesDialog(FileSystemEntity entity) {
    final properties = EntityOperator.getFileProperties(entity);
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
  }

  void _deleteSelectedItems() {
    _showConfirmDialog('确认删除${_controller.selectedEntities}?', onConfirm: () {
      EntityOperator.deleteEntities(_controller.selectedEntities)
          .then((message) {
        _controller.cancelMultiSelect();
        _controller.loadEntitiesAndNotify();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      });
      Navigator.pop(context);
    });
  }

  Future<void> _pasteEntities() async {
    if (!BrowserClipboard.canPaste.value) {
      return;
    }
    BrowserClipboard.paste(_controller.currentNode.path).then((messages) {
      _controller.loadEntitiesAndNotify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$messages')),
        );
      }
    });
  }
}
