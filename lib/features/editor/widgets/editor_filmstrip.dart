import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

String _time(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';

class EditorFilmstrip extends ConsumerWidget {
  const EditorFilmstrip({
    super.key,
    required this.clips,
    required this.selectedId,
    this.current,
    required this.audioPath,
    required this.onSelect,
    required this.onEditClip,
    required this.onReorder,
    required this.onAdd,
  });
  final List<MediaTrackClipPayload> clips;
  final String? selectedId;
  final Duration? current;
  final String? audioPath;
  final ValueChanged<MediaTrackClipPayload> onSelect;
  final ValueChanged<MediaTrackClipPayload> onEditClip;
  final void Function(int, int) onReorder;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Duration current =
        this.current ??
        ref.watch(
          playbackViewModelProvider.select(
            (state) => state.asData?.value.currentTime ?? Duration.zero,
          ),
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final activeCaption = clips
            .where(
              (clip) => clip.clipId == selectedId && clip.caption.isNotEmpty,
            )
            .firstOrNull;
        return Column(
          children: [
            SizedBox(
              height: math.min(120, constraints.maxHeight),
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: clips.length + 1,
                onReorderItem: onReorder,
                itemBuilder: (context, index) {
                  if (index == clips.length) {
                    return SizedBox(
                      key: const ValueKey('add-clip'),
                      width: 64,
                      child: IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                      ),
                    );
                  }
                  final clip = clips[index];
                  final selected = clip.clipId == selectedId;
                  final span = clip.end - clip.start;
                  final width = (span.inMilliseconds / 1000 * 28).clamp(
                    80.0,
                    240.0,
                  );
                  final isPlayingClip =
                      current >= clip.start &&
                      current < clip.end &&
                      span > Duration.zero;
                  final fraction = isPlayingClip
                      ? (current - clip.start).inMilliseconds /
                            span.inMilliseconds
                      : 0.0;
                  return Padding(
                    key: ValueKey(clip.clipId),
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _time(clip.start),
                                  style: context.textTheme.labelSmall,
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Tooltip(
                                  message: context.l10n.reorder,
                                  child: Icon(
                                    Icons.drag_handle,
                                    size: 20,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => onSelect(clip),
                              onLongPress: () => onEditClip(clip),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selected
                                        ? context.colors.primary
                                        : context
                                              .colors
                                              .surfaceContainerHighest,
                                    width: selected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      MediaThumbnail(path: clip.sourcePath),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: ColoredBox(
                                          color: context.colors.surface,
                                          child: Text(
                                            '${((clip.end - clip.start).inMilliseconds / 1000).toStringAsFixed(1)} s',
                                            style: context.textTheme.labelSmall,
                                          ),
                                        ),
                                      ),
                                      if (isPlayingClip)
                                        Positioned(
                                          left: (width - 6) * fraction,
                                          top: 0,
                                          bottom: 0,
                                          child: SizedBox(
                                            width: 2,
                                            child: ColoredBox(
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (audioPath != null &&
                audioPath!.isNotEmpty &&
                constraints.maxHeight >= 160)
              _TrackLabel(
                icon: Icons.music_note,
                text: audioPath!.split(RegExp(r'[\\/]')).last,
              ),
            if (activeCaption != null && constraints.maxHeight >= 200)
              _TrackLabel(icon: Icons.text_fields, text: activeCaption.caption),
          ],
        );
      },
    );
  }
}

class _TrackLabel extends StatelessWidget {
  const _TrackLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ],
    ),
  );
}
