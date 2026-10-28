import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_status_message.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryToolbar extends ConsumerWidget {
  const LibraryToolbar({
    required this.visibleCount,
    required this.stagedCount,
    super.key,
  });

  final int visibleCount;
  final int stagedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final viewModel = ref.read(libraryViewModelProvider.notifier);
    final folderPathsUnavailable =
        defaultTargetPlatform == TargetPlatform.android;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.searchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.librarySearchHint,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final filter in LibraryFilter.values)
                  FilterChip(
                    selected: state.selectedFilter == filter,
                    onSelected: (_) => viewModel.filterSelected(filter),
                    label: Text(_filterLabel(context, filter)),
                  ),
                const SizedBox(width: 8),
                DropdownMenu<LibrarySortOrder>(
                  initialSelection: state.sortOrder,
                  leadingIcon: const Icon(Icons.sort),
                  label: Text(context.l10n.librarySort),
                  dropdownMenuEntries: [
                    for (final order in LibrarySortOrder.values)
                      DropdownMenuEntry(
                        value: order,
                        label: _sortLabel(context, order),
                      ),
                  ],
                  onSelected: (order) {
                    if (order == null) {
                      return;
                    }
                    viewModel.sortOrderSelected(order);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    context.l10n.libraryImportedCount(state.totalCount),
                  ),
                ),
                Chip(
                  label: Text(context.l10n.libraryVisibleCount(visibleCount)),
                ),
                Chip(label: Text(context.l10n.libraryStagedCount(stagedCount))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.folderPathChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.folder_open_outlined),
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
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(context.l10n.libraryImportMore),
                ),
                OutlinedButton.icon(
                  onPressed: state.isImporting
                      ? null
                      : folderPathsUnavailable
                      ? viewModel.importImagesFromFolderPicker
                      : viewModel.importImagesFromFolderPath,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: Text(context.l10n.importFolder),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      state.isImporting ||
                          state.items.isEmpty ||
                          stagedCount == state.totalCount
                      ? null
                      : () => ref
                            .read(
                              editorMediaSelectionViewModelProvider.notifier,
                            )
                            .addAllMedia(state.items),
                  icon: const Icon(Icons.playlist_add_check),
                  label: Text(context.l10n.libraryStageAllImported),
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

  String _filterLabel(BuildContext context, LibraryFilter filter) {
    return switch (filter) {
      LibraryFilter.all => context.l10n.libraryFilterAll,
      LibraryFilter.recent => context.l10n.libraryFilterRecent,
      LibraryFilter.staged => context.l10n.libraryFilterStaged,
      LibraryFilter.favorites => context.l10n.libraryFilterFavorites,
    };
  }

  String _sortLabel(BuildContext context, LibrarySortOrder order) {
    return switch (order) {
      LibrarySortOrder.newest => context.l10n.librarySortNewest,
      LibrarySortOrder.oldest => context.l10n.librarySortOldest,
      LibrarySortOrder.name => context.l10n.librarySortByName,
      LibrarySortOrder.fileSize => context.l10n.librarySortByFileSize,
    };
  }
}
