import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    this.item,
    this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth = 400,
    this.alignment = Alignment.center,
  });
  final LibraryMediaItem? item;
  final String? path;
  final BoxFit fit;
  final int? cacheWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget error(BuildContext context, Object error, StackTrace? stack) =>
        ColoredBox(
          color: context.colors.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: context.colors.onSurfaceVariant,
          ),
        );
    final bytes = item?.thumbnailBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        cacheWidth: cacheWidth,
        errorBuilder: error,
      );
    }
    final source = item?.sourcePath ?? path ?? '';
    if (source.isEmpty) {
      return error(context, StateError('Missing image'), null);
    }
    return Image.file(
      File(source),
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      errorBuilder: error,
      frameBuilder: (context, child, frame, synchronous) =>
          frame == null && !synchronous
          ? ColoredBox(
              color: context.colors.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            )
          : child,
    );
  }
}
