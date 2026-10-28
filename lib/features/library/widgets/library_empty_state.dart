import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_status_message.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({
    required this.visibleCount,
    required this.selectedCount,
    super.key,
  });

  final int visibleCount;
  final int selectedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final viewModel = ref.read(libraryViewModelProvider.notifier);
    final folderPathsUnavailable =
        defaultTargetPlatform == TargetPlatform.android;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.importImagesHeading,
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.libraryDescription,
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(context.l10n.libraryVisibleCount(visibleCount)),
                ),
                Chip(label: Text(context.l10n.libraryImportedCount(0))),
                Chip(
                  label: Text(context.l10n.libraryInEditorCount(selectedCount)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              enabled: !state.isImporting && !folderPathsUnavailable,
              onChanged: viewModel.folderPathChanged,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.folder_open_outlined),
                hintText: folderPathsUnavailable
                    ? null
                    : context.l10n.pasteFolderPath,
              ),
            ),
            if (folderPathsUnavailable) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.folderPathUnavailableOnAndroid,
                style: context.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.isImporting ? null : viewModel.pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.l10n.pickImages),
                ),
                OutlinedButton.icon(
                  onPressed: state.isImporting || folderPathsUnavailable
                      ? null
                      : viewModel.importImagesFromFolderPath,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: Text(context.l10n.importFolder),
                ),
              ],
            ),
            if (state.isImporting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (state.importStatus != null) ...[
              const SizedBox(height: 16),
              LibraryStatusMessage(
                status: state.importStatus,
                count: state.statusItemCount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
