import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
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

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.searchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search images, folders, or dates',
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
                    label: Text(_filterLabel(filter)),
                  ),
                const SizedBox(width: 8),
                DropdownMenu<LibrarySortOrder>(
                  initialSelection: state.sortOrder,
                  leadingIcon: const Icon(Icons.sort),
                  label: const Text('Sort'),
                  dropdownMenuEntries: [
                    for (final order in LibrarySortOrder.values)
                      DropdownMenuEntry(value: order, label: _sortLabel(order)),
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
                Chip(label: Text('Imported: ${state.totalCount}')),
                Chip(label: Text('Visible: $visibleCount')),
                Chip(label: Text('Staged: $stagedCount')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.folderPathChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.folder_open_outlined),
                hintText: 'Paste folder path',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.isImporting ? null : viewModel.pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import more'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isImporting
                      ? null
                      : viewModel.importImagesFromFolderPath,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: const Text('Import folder'),
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
            if (state.statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(state.statusMessage!, style: context.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String _filterLabel(LibraryFilter filter) {
    return switch (filter) {
      LibraryFilter.all => 'All',
      LibraryFilter.recent => 'Recent',
      LibraryFilter.staged => 'Staged',
      LibraryFilter.favorites => 'Favorites',
    };
  }

  String _sortLabel(LibrarySortOrder order) {
    return switch (order) {
      LibrarySortOrder.newest => 'Newest',
      LibrarySortOrder.oldest => 'Oldest',
      LibrarySortOrder.name => 'Name',
      LibrarySortOrder.fileSize => 'File size',
    };
  }
}
