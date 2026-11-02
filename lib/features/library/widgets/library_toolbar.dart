import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_error_message.dart';
import 'package:picturestovideos/features/library/widgets/library_status_message.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

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
    final model = ref.read(libraryViewModelProvider.notifier);
    final android = defaultTargetPlatform == TargetPlatform.android;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          enabled: !state.isImporting,
          onChanged: model.searchChanged,
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
                if (order != null) model.sortOrderSelected(order);
              },
            ),
            OutlinedButton.icon(
              onPressed: state.isImporting ? null : model.pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(context.l10n.libraryImportMore),
            ),
            TextButton.icon(
              onPressed: state.isImporting || stagedCount == state.totalCount
                  ? null
                  : () => ref
                        .read(editorMediaSelectionViewModelProvider.notifier)
                        .addAllMedia(state.items),
              icon: const Icon(Icons.playlist_add_check),
              label: Text(context.l10n.libraryStageAllImported),
            ),
            if (stagedCount > 0)
              TextButton(
                onPressed: model.reviewStagedOpened,
                child: Text(context.l10n.libraryReviewStaged),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in LibraryFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: state.selectedFilter == filter,
                    onSelected: (_) => model.filterSelected(filter),
                    label: Text(_filterLabel(context, filter)),
                  ),
                ),
            ],
          ),
        ),
        ExpansionTile(
          title: Text(context.l10n.importFolder),
          children: [
            if (!android)
              TextField(
                enabled: !state.isImporting,
                onChanged: model.folderPathChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.folder_open_outlined),
                  hintText: context.l10n.pasteFolderPath,
                ),
              ),
            TextButton.icon(
              onPressed: state.isImporting
                  ? null
                  : android
                  ? model.importImagesFromFolderPicker
                  : model.importImagesFromFolderPath,
              icon: const Icon(Icons.drive_folder_upload_outlined),
              label: Text(context.l10n.importFolder),
            ),
          ],
        ),
        if (state.isImporting) const LinearProgressIndicator(),
        if (state.error != null) LibraryErrorMessage(error: state.error),
        if (state.importStatus != null)
          LibraryStatusMessage(
            status: state.importStatus,
            count: state.statusItemCount,
          ),
      ],
    );
  }

  String _filterLabel(BuildContext context, LibraryFilter filter) =>
      switch (filter) {
        LibraryFilter.all => context.l10n.libraryFilterAll,
        LibraryFilter.recent => context.l10n.libraryFilterRecent,
        LibraryFilter.staged => context.l10n.libraryFilterStaged,
        LibraryFilter.favorites => context.l10n.libraryFilterFavorites,
      };

  String _sortLabel(BuildContext context, LibrarySortOrder order) =>
      switch (order) {
        LibrarySortOrder.newest => context.l10n.librarySortNewest,
        LibrarySortOrder.oldest => context.l10n.librarySortOldest,
        LibrarySortOrder.name => context.l10n.librarySortByName,
        LibrarySortOrder.fileSize => context.l10n.librarySortByFileSize,
      };
}
