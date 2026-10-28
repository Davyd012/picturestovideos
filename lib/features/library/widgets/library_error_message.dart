import 'package:flutter/material.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryErrorMessage extends StatelessWidget {
  const LibraryErrorMessage({required this.error, super.key});

  final LibraryError? error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      LibraryError.importFailed => context.l10n.libraryImportFailed,
      LibraryError.folderPathRequired => context.l10n.libraryFolderPathRequired,
      LibraryError.folderNotFound => context.l10n.libraryFolderNotFound,
      LibraryError.folderReadFailed => context.l10n.libraryFolderReadFailed,
      LibraryError.removeFailed => context.l10n.libraryRemovalFailed,
      null => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Text(
      message,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.error,
      ),
    );
  }
}
