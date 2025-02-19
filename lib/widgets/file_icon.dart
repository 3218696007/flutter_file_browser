import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

class FileIconWidget extends StatelessWidget {
  final FileSystemEntity entity;
  final double size;

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
      FileType.pdf =>
        Icon(Icons.picture_as_pdf, size: size, color: primaryColor),
      FileType.video =>
        Icon(Icons.video_library, size: size, color: primaryColor),
      FileType.unknown =>
        Icon(Icons.insert_drive_file, size: size, color: primaryColor),
    };
  }
}
