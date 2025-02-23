import 'dart:io';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

// path_provider
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

class FileIconWidget extends StatelessWidget {
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

  const FileIconWidget({
    super.key,
    required this.entity,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (entity is Directory) {
      return Icon(Icons.folder, size: size, color: primaryColor);
    }

    final fileType = FileUtils.getFileType(entity.path);
    return switch (fileType) {
      FileType.archive => Icon(Icons.archive, size: size, color: primaryColor),
      FileType.audio => Icon(Icons.audiotrack, size: size, color: primaryColor),
      FileType.document =>
        Icon(Icons.description, size: size, color: primaryColor),
      FileType.image => Image.file(entity as File, width: size, height: size),
      FileType.mindMap => Icon(Icons.map, size: size, color: primaryColor),
      FileType.pdf => Icon(Icons.picture_as_pdf, size: size, color: Colors.red),
      FileType.video => FutureBuilder(
          future: _getVideoThumbnail(entity.path, size),
          builder: (context, snapshot) {
            return snapshot.connectionState != ConnectionState.done
                ? const CircularProgressIndicator()
                : snapshot.hasData
                    ? snapshot.data
                    : Icon(
                        Icons.question_mark,
                        size: size,
                        color: primaryColor,
                      );
          },
        ),
      FileType.unknown =>
        Icon(Icons.insert_drive_file, size: size, color: primaryColor),
      FileType.word =>
        Icon(Icons.insert_drive_file, size: size, color: Colors.blue),
      FileType.excel =>
        Icon(Icons.insert_drive_file, size: size, color: Colors.teal),
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
