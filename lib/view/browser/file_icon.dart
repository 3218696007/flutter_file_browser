import 'dart:io';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../../service/entity_extension.dart';

class FileIcon extends StatelessWidget {
  final FileSystemEntity entity;
  final double size;
  static final fcNativeVideoThumbnail = FcNativeVideoThumbnail();
  static String? _videoThumbnailDirectory;

  Future<String> get videoThumbnailDirectory async {
    if (_videoThumbnailDirectory != null) return _videoThumbnailDirectory!;
    final appDocDir = await getApplicationCacheDirectory();
    _videoThumbnailDirectory =
        '${appDocDir.path}${Platform.pathSeparator}video_thumbnail';
    if (!await Directory(_videoThumbnailDirectory!).exists()) {
      await Directory(_videoThumbnailDirectory!).create();
    }
    return _videoThumbnailDirectory!;
  }

  const FileIcon({
    super.key,
    required this.entity,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final directoryColor = Theme.of(context).colorScheme.primary;
    const fileColor = Colors.grey;
    if (entity is Directory) {
      return Icon(Icons.folder, size: size, color: directoryColor);
    }
    return switch (entity.type) {
      EntityType.audio => Icon(Icons.audiotrack, size: size, color: fileColor),
      EntityType.image => LazyBuilder(
          child: Image.file(
            entity as File,
            width: size,
            height: size,
            cacheWidth: size.toInt(),
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => Icon(Icons.image, size: size),
          ),
        ),
      EntityType.video => LazyBuilder(
          child: FutureBuilder(
            future: _getVideoThumbnail(entity.path, size),
            builder: (context, snapshot) {
              return snapshot.connectionState != ConnectionState.done
                  ? const CircularProgressIndicator()
                  : snapshot.hasData
                      ? snapshot.data
                      : Icon(Icons.question_mark, size: size, color: fileColor);
            },
          ),
        ),
      EntityType.word => MyFileIcon(text: 'W', size: size, color: Colors.blue),
      EntityType.excel => MyFileIcon(text: 'E', size: size, color: Colors.teal),
      EntityType.ppt => MyFileIcon(text: 'P', size: size, color: Colors.orange),
      EntityType.pdf => MyFileIcon(text: 'PDF', size: size, color: Colors.red),
      EntityType.mindMap =>
        MyFileIcon(text: 'M', size: size, color: Colors.green),
      EntityType.document =>
        Icon(Icons.description, size: size, color: fileColor),
      EntityType.archive =>
        Icon(Icons.folder_zip, size: size, color: Colors.brown),
      EntityType.unknown =>
        Icon(Icons.question_mark, size: size, color: fileColor),
    };
  }

  Future _getVideoThumbnail(String path, double size) async {
    final destFilePath =
        '${await videoThumbnailDirectory}${Platform.pathSeparator}${path.hashCode}.jpeg';
    if (await File(destFilePath).exists()) {
      return Image.file(File(destFilePath), width: size, height: size);
    }
    final result = await fcNativeVideoThumbnail.getVideoThumbnail(
      srcFile: path,
      destFile: destFilePath,
      width: size.toInt(),
      height: size.toInt(),
    );
    if (result) {
      return Image.file(File(destFilePath), width: size, height: size);
    }
    debugPrint('${entity.path}缩略图获取失败');
  }
}

class LazyBuilder extends StatelessWidget {
  const LazyBuilder({
    super.key,
    this.duration = const Duration(milliseconds: 500),
    required this.child,
  });

  final Duration duration;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final show = ValueNotifier(false);
    Future.delayed(duration, () => show.value = true);
    return ValueListenableBuilder(
      valueListenable: show,
      builder: (_, value, __) =>
          value ? child : const CircularProgressIndicator(),
    );
  }
}

class MyFileIcon extends StatelessWidget {
  const MyFileIcon({
    super.key,
    this.iconData = Icons.insert_drive_file,
    this.text = 'file',
    required this.size,
    required this.color,
  });

  final IconData iconData;

  final String text;

  final double size;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(iconData, size: size, color: color),
        Positioned(
          bottom: 0.1 * size,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 0.3 * size,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
