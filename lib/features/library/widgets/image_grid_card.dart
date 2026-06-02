import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ImageGridCard extends ConsumerWidget {
  const ImageGridCard({
    required this.item,
    required this.isStaged,
    required this.isSelected,
    super.key,
  });

  final LibraryMediaItem item;
  final bool isStaged;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: isSelected ? 4 : 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleStaged(ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _StatusBadge(isStaged: isStaged),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: context.colors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sizeLabel} - ${item.importedOnLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.sourcePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _toggleStaged(ref),
                    icon: Icon(isStaged ? Icons.check : Icons.add),
                    label: Text(isStaged ? 'Staged' : 'Stage'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStaged(WidgetRef ref) {
    ref.read(editorMediaSelectionViewModelProvider.notifier).toggleMedia(item);
    if (isStaged) {
      ref.read(libraryViewModelProvider.notifier).itemSelectionRemoved(item.id);
      return;
    }
    if (!isSelected) {
      ref.read(libraryViewModelProvider.notifier).itemSelectionToggled(item.id);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isStaged});

  final bool isStaged;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(isStaged ? Icons.check : Icons.image_outlined),
      label: Text(isStaged ? 'Staged' : 'Ready'),
    );
  }
}
