import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipsTabView extends StatelessWidget {
  const ClipsTabView({
    required this.selectedMedia,
    required this.onReorderMedia,
    required this.onOpenTimeline,
    super.key,
  });

  final List<LibraryMediaItem> selectedMedia;
  final void Function(int oldIndex, int newIndex) onReorderMedia;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    final clips = selectedMedia.isEmpty ? _sampleClips : selectedMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Queued image clips (${clips.length})',
                style: context.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: null,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Reorder'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedMedia.isEmpty)
          for (var index = 0; index < clips.length; index++) ...[
            _ClipListItem(item: clips[index], index: index, canReorder: false),
            const SizedBox(height: 8),
          ]
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: selectedMedia.length,
            onReorderItem: onReorderMedia,
            itemBuilder: (context, index) {
              final item = selectedMedia[index];
              return Padding(
                key: ValueKey(item.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _ClipListItem(
                  item: item,
                  index: index,
                  canReorder: selectedMedia.length > 1,
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: selectedMedia.isEmpty ? null : onOpenTimeline,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Review sequence'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onOpenTimeline,
              icon: const Icon(Icons.timeline),
              label: const Text('Open timeline'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClipListItem extends StatelessWidget {
  const _ClipListItem({
    required this.item,
    required this.index,
    required this.canReorder,
  });

  final LibraryMediaItem item;
  final int index;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        minVerticalPadding: 12,
        leading: _Thumbnail(item: item),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_formatDuration(Duration(seconds: index * 3))}  /  3s',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReorder)
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: context.colors.onSurfaceVariant,
                ),
              )
            else
              Icon(Icons.drag_handle, color: context.colors.onSurfaceVariant),
            IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final LibraryMediaItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(dimension: 56, child: _thumbnail(context)),
    );
  }

  Widget _thumbnail(BuildContext context) {
    if (item.thumbnailBytes.isNotEmpty) {
      return Image.memory(item.thumbnailBytes, fit: BoxFit.cover);
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
      color: context.colors.primaryContainer,
      child: Icon(
        Icons.image_outlined,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }
}

final _sampleClips = [
  _sampleClip('sample-01', 'IMG_1042.jpg', 'Opening frame'),
  _sampleClip('sample-02', 'IMG_1088.jpg', 'Beat cut'),
  _sampleClip('sample-03', 'IMG_1130.jpg', 'Memory beat'),
  _sampleClip('sample-04', 'IMG_1192.jpg', 'Caption frame'),
];

LibraryMediaItem _sampleClip(String id, String title, String tagline) {
  return LibraryMediaItem(
    id: id,
    title: title,
    sizeLabel: '2.4 MB',
    tagline: tagline,
    importedOnLabel: 'Jun 02, 2026',
    importedOn: DateTime(2026, 6, 2),
    byteLength: 2400000,
    thumbnailBytes: Uint8List(0),
    sourcePath: '',
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
