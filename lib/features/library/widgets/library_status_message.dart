import 'package:flutter/material.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryStatusMessage extends StatelessWidget {
  const LibraryStatusMessage({
    required this.status,
    required this.count,
    super.key,
  });

  final LibraryImportStatus? status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      LibraryImportStatus.noNewImages => context.l10n.libraryNoNewImages,
      LibraryImportStatus.imagesAdded => context.l10n.libraryImagesAdded(count),
      LibraryImportStatus.imagesRemoved => context.l10n.libraryImagesRemoved(
        count,
      ),
      null => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Text(message, style: context.textTheme.bodyMedium);
  }
}
