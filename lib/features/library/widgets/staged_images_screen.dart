import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class StagedImagesScreen extends ConsumerWidget {
  const StagedImagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagedItems = ref.watch(
      editorMediaSelectionViewModelProvider.select((state) {
        return state.selectedMedia;
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = EdgeInsets.all(constraints.maxWidth >= 960 ? 32 : 24);

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: ref
                        .read(libraryViewModelProvider.notifier)
                        .libraryOpened,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staged images',
                          style: context.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Drag to reorder the clip sequence for the editor.',
                          style: context.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: stagedItems.isEmpty
                    ? const _NoStagedImagesCard()
                    : ReorderableStagedList(items: stagedItems),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: stagedItems.isEmpty
                        ? null
                        : () => context.appNavigator.goToAudioEditor(),
                    icon: const Icon(Icons.tune),
                    label: const Text('Open editor'),
                  ),
                  OutlinedButton.icon(
                    onPressed: stagedItems.isEmpty
                        ? null
                        : () => _clearStaged(ref),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear staged'),
                  ),
                  TextButton.icon(
                    onPressed: ref
                        .read(libraryViewModelProvider.notifier)
                        .libraryOpened,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Back to library'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearStaged(WidgetRef ref) {
    ref.read(editorMediaSelectionViewModelProvider.notifier).clearSelection();
    ref.read(libraryViewModelProvider.notifier).clearItemSelection();
  }
}

class ReorderableStagedList extends ConsumerWidget {
  const ReorderableStagedList({required this.items, super.key});

  final List<LibraryMediaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      itemCount: items.length,
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        ref
            .read(editorMediaSelectionViewModelProvider.notifier)
            .reorderMedia(oldIndex: oldIndex, newIndex: newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return StagedImageTile(
          key: ValueKey(item.id),
          item: item,
          index: index,
        );
      },
    );
  }
}

class StagedImageTile extends ConsumerWidget {
  const StagedImageTile({required this.item, required this.index, super.key});

  final LibraryMediaItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _TileThumbnail(item: item),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '#${index + 1} - ${item.sizeLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}

class _TileThumbnail extends StatelessWidget {
  const _TileThumbnail({required this.item});

  final LibraryMediaItem item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _thumbnail(context),
      ),
    );
  }

  Widget _thumbnail(BuildContext context) {
    if (item.thumbnailBytes.isNotEmpty) {
      return Image.memory(
        item.thumbnailBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    if (item.sourcePath.isNotEmpty) {
      return Image.file(
        File(item.sourcePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class _NoStagedImagesCard extends ConsumerWidget {
  const _NoStagedImagesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_outlined,
              size: 48,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text('No staged images', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Stage images from the library before reviewing the editor queue.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: ref
                  .read(libraryViewModelProvider.notifier)
                  .libraryOpened,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Back to library'),
            ),
          ],
        ),
      ),
    );
  }
}
