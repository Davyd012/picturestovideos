import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final editorSelection = ref.watch(editorMediaSelectionViewModelProvider);

    return AppShellScaffold(
      currentRoute: AppRoutes.library,
      title: 'Library',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: editorSelection.hasSelection
                ? () => context.appNavigator.goToAudioEditor()
                : null,
            icon: const Icon(Icons.playlist_add),
            label: Text('Open editor (${editorSelection.selectedCount})'),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = EdgeInsets.all(constraints.maxWidth >= 960 ? 32 : 24);

          return ListView(
            padding: padding,
            children: [
              Text('Image library', style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Import images, stage the strongest frames, and send them into the beat-synced editor flow.',
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _LibraryToolbar(
                state: state,
                editorSelection: editorSelection,
              ),
              const SizedBox(height: 24),
              if (state.filteredItems.isEmpty)
                _EmptyLibraryState(hasItems: state.hasItems)
              else
                _LibraryGrid(
                  items: state.filteredItems,
                  editorSelection: editorSelection,
                ),
              const SizedBox(height: 24),
              const _QuickAddActions(),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryToolbar extends ConsumerWidget {
  const _LibraryToolbar({
    required this.state,
    required this.editorSelection,
  });

  final LibraryState state;
  final EditorMediaSelectionState editorSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(libraryViewModelProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.searchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search imported images or dates',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.folderPathChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.folder_open_outlined),
                hintText: 'Paste a folder path to import supported images',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _LibrarySummaryChip(
                  label: 'Visible images',
                  value: '${state.visibleCount}',
                ),
                _LibrarySummaryChip(
                  label: 'Imported',
                  value: '${state.totalCount}',
                ),
                _LibrarySummaryChip(
                  label: 'In editor',
                  value: '${editorSelection.selectedCount}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: state.isImporting ? null : viewModel.pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Pick images'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isImporting
                      ? null
                      : viewModel.importImagesFromFolderPath,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: const Text('Import folder'),
                ),
                OutlinedButton.icon(
                  onPressed: state.filteredItems.isEmpty || state.isImporting
                      ? null
                      : () => ref
                          .read(editorMediaSelectionViewModelProvider.notifier)
                          .addAllMedia(state.filteredItems),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add visible images'),
                ),
                if (editorSelection.hasSelection)
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(editorMediaSelectionViewModelProvider.notifier)
                        .clearSelection(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear editor picks'),
                  ),
              ],
            ),
            if (state.isImporting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (state.statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.statusMessage!,
                style: context.textTheme.bodyMedium,
              ),
            ],
            if (!editorSelection.hasSelection) ...[
              const SizedBox(height: 12),
              Text(
                'Tap image cards to stage them for the editor timeline.',
                style: context.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibrarySummaryChip extends StatelessWidget {
  const _LibrarySummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({
    required this.items,
    required this.editorSelection,
  });

  final List<LibraryMediaItem> items;
  final EditorMediaSelectionState editorSelection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          > 1200 => 5,
          > 900 => 4,
          > 640 => 3,
          _ => 2,
        };

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _LibraryCard(
              item: item,
              isSelected: editorSelection.containsMedia(item.id),
            );
          },
        );
      },
    );
  }
}

class _LibraryCard extends ConsumerWidget {
  const _LibraryCard({
    required this.item,
    required this.isSelected,
  });

  final LibraryMediaItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref
            .read(editorMediaSelectionViewModelProvider.notifier)
            .toggleMedia(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    item.thumbnailBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: context.colors.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                  if (isSelected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Chip(
                          avatar: const Icon(Icons.check_circle_outline),
                          label: const Text('Queued'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSelected) Chip(label: Text(item.sizeLabel)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.importedOnLabel} • ${item.sourcePath}',
                    style: context.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      ref
                          .read(editorMediaSelectionViewModelProvider.notifier)
                          .addMedia(item);
                      context.appNavigator.goToAudioEditor();
                    },
                    icon: Icon(isSelected ? Icons.check : Icons.add),
                    label: Text(isSelected ? 'Open in editor' : 'Queue image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.hasItems});

  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 32, color: context.colors.primary),
            const SizedBox(height: 16),
            Text(
              hasItems ? 'No matching images' : 'No images imported yet',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasItems
                  ? 'Try a broader search to see more imported images.'
                  : 'Pick images or import a folder path to start building the video from real files.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddActions extends StatelessWidget {
  const _QuickAddActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick add actions', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToImportAudio(),
                  icon: const Icon(Icons.audio_file_outlined),
                  label: const Text('Import more audio'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToAudioEditor(),
                  icon: const Icon(Icons.tune),
                  label: const Text('Open image editor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToDownload(),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Go to export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
