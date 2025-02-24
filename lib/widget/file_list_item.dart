// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'file_icon.dart';
// import '../models/file_manager_controller.dart';

// class FileListItem extends StatelessWidget {
//   final FileSystemEntity entity;
//   final VoidCallback? onTap;
//   final bool isGridView;

//   const FileListItem({
//     super.key,
//     required this.entity,
//     this.onTap,
//     this.isGridView = false,
//   });

//   List<PopupMenuEntry<String>> _buildMenuItems(
//       BuildContext context, String fileName) {
//     return [
//       const PopupMenuItem<String>(
//         value: 'open',
//         child: ListTile(
//           leading: Icon(Icons.open_in_new),
//           title: Text('打开'),
//           contentPadding: EdgeInsets.zero,
//         ),
//       ),
//       const PopupMenuItem<String>(
//         value: 'rename',
//         child: ListTile(
//           leading: Icon(Icons.drive_file_rename_outline),
//           title: Text('重命名'),
//           contentPadding: EdgeInsets.zero,
//         ),
//       ),
//       const PopupMenuItem<String>(
//         value: 'delete',
//         child: ListTile(
//           leading: Icon(Icons.delete_outline),
//           title: Text('删除'),
//           contentPadding: EdgeInsets.zero,
//         ),
//       ),
//       const PopupMenuItem<String>(
//         value: 'properties',
//         child: ListTile(
//           leading: Icon(Icons.info_outline),
//           title: Text('属性'),
//           contentPadding: EdgeInsets.zero,
//         ),
//       ),
//     ];
//   }

//   Future<void> _handleMenuAction(
//       BuildContext context, String action, String fileName) async {
//     final controller =
//         Provider.of<FileManagerController>(context, listen: false);

//     switch (action) {
//       case 'open':
//         onTap?.call();
//         break;
//       case 'rename':
//         String? newName = await showDialog<String>(
//           context: context,
//           builder: (BuildContext context) {
//             String newFileName = fileName;
//             return AlertDialog(
//               title: const Text('重命名'),
//               content: TextField(
//                 autofocus: true,
//                 controller: TextEditingController(text: fileName),
//                 decoration: const InputDecoration(hintText: '请输入新名称'),
//                 onChanged: (value) {
//                   newFileName = value;
//                 },
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('取消'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, newFileName),
//                   child: const Text('确定'),
//                 ),
//               ],
//             );
//           },
//         );
//         if (newName != null && newName.isNotEmpty && newName != fileName) {
//           try {
//             await controller.renameFile(entity, newName);
//           } catch (e) {
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(e.toString())),
//               );
//             }
//           }
//         }
//         break;
//       case 'delete':
//         bool? confirm = await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) => AlertDialog(
//             title: const Text('确认删除'),
//             content: Text('确定要删除 "$fileName" 吗？'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('取消'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text('确定'),
//               ),
//             ],
//           ),
//         );
//         if (confirm == true) {
//           try {
//             await controller.deleteFile(entity);
//           } catch (e) {
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(e.toString())),
//               );
//             }
//           }
//         }
//         break;
//       case 'properties':
//         try {
//           final properties = await controller.getFileProperties(entity);
//           if (context.mounted) {
//             showDialog(
//               context: context,
//               builder: (BuildContext context) => AlertDialog(
//                 title: const Text('文件属性'),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: properties.entries
//                         .map((entry) => Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text('${entry.key}：',
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold)),
//                                   const SizedBox(width: 8),
//                                   Expanded(child: Text(entry.value.toString())),
//                                 ],
//                               ),
//                             ))
//                         .toList(),
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('确定'),
//                   ),
//                 ],
//               ),
//             );
//           }
//         } catch (e) {
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(e.toString())),
//             );
//           }
//         }
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final fileName = entity.path.split(Platform.pathSeparator).last;
//     final menuButton = PopupMenuButton<String>(
//       itemBuilder: (context) => _buildMenuItems(context, fileName),
//       onSelected: (action) => _handleMenuAction(context, action, fileName),
//     );

//     return isGridView
//         ? InkWell(
//             onTap: onTap,
//             onLongPress: () => _showContextMenu(context),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 FileIconWidget(entity: entity),
//                 // menuButton,
//                 const SizedBox(height: 4),
//                 Text(
//                   fileName,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           )
//         : ListTile(
//             leading: FileIconWidget(entity: entity),
//             title: Text(fileName),
//             onTap: onTap,
//             onLongPress: () => _showContextMenu(context),
//             trailing: menuButton,
//           );
//   }

//   void _showContextMenu(BuildContext context) {
//     final RenderBox button = context.findRenderObject() as RenderBox;
//     final Offset position = button.localToGlobal(Offset.zero);
//     showMenu(
//       context: context,
//       position: RelativeRect.fromLTRB(
//         position.dx,
//         position.dy,
//         position.dx + button.size.width,
//         position.dy + button.size.height,
//       ),
//       items: _buildMenuItems(
//           context, entity.path.split(Platform.pathSeparator).last),
//     ).then((String? action) {
//       if (action != null) {
//         _handleMenuAction(
//             context, action, entity.path.split(Platform.pathSeparator).last);
//       }
//     });
//   }
// }
