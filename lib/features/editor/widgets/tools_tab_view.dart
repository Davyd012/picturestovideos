import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ToolsTabView extends ConsumerWidget {
  const ToolsTabView({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.selectedTemplate,
    required this.selectedMedia,
    required this.selectedMarker,
    required this.events,
    required this.eventStatusText,
    required this.audioDuration,
    required this.onAddMarker,
    required this.onAddImagePoint,
    required this.onDeleteMarker,
    required this.onDeleteMarkerAtCurrentPoint,
    required this.onClearMarkers,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final VideoTemplate selectedTemplate;
  final List<LibraryMediaItem> selectedMedia;
  final TimelineMarkerSelection? selectedMarker;
  final List<BeatEvent> events;
  final String eventStatusText;
  final Duration? audioDuration;
  final VoidCallback onAddMarker;
  final VoidCallback onAddImagePoint;
  final VoidCallback onDeleteMarker;
  final VoidCallback onDeleteMarkerAtCurrentPoint;
  final VoidCallback onClearMarkers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMediaTrack =
        project?.tracks.any((track) => track.id == 'track-media') ?? false;
    final canAutoSync = beatMap != null && selectedMedia.isNotEmpty;
    final canEditMarkers =
        project?.tracks.any(
          (track) => track.id == 'track-markers' && track.events.isNotEmpty,
        ) ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedTemplate.id,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.auto_awesome_mosaic_outlined),
                    labelText: 'Video preset',
                  ),
                  items: [
                    for (final template in VideoTemplates.all)
                      DropdownMenuItem(
                        value: template.id,
                        child: Text(template.name),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == null) {
                      return;
                    }
                    ref
                        .read(timelineViewModelProvider.notifier)
                        .templateSelected(VideoTemplates.byId(id));
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VideoTemplateAspectRatio>(
                  initialValue: selectedTemplate.aspectRatio,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.aspect_ratio_outlined),
                    labelText: 'Aspect ratio',
                  ),
                  items: [
                    for (final ratio in VideoTemplateAspectRatio.values)
                      DropdownMenuItem(
                        value: ratio,
                        child: Text(ratio.menuLabel),
                      ),
                  ],
                  onChanged: (ratio) {
                    if (ratio == null) {
                      return;
                    }
                    ref
                        .read(timelineViewModelProvider.notifier)
                        .aspectRatioSelected(ratio);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  selectedTemplate.description,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(selectedTemplate.aspectRatio.label)),
                    Chip(label: Text(_clipDurationLabel(selectedTemplate))),
                    Chip(label: Text(selectedTemplate.transition.name)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(beatMap == null ? 'Sync inactive' : 'Sync active'),
            ),
            Chip(
              label: Text(playback?.isPlaying ?? false ? 'Playing' : 'Paused'),
            ),
            Chip(
              label: Text(
                hasMediaTrack ? 'Image track ready' : 'No image track',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: canAutoSync
              ? () => ref
                    .read(timelineViewModelProvider.notifier)
                    .buildProjectTimeline(
                      beatMap: beatMap!,
                      events: events,
                      selectedMedia: selectedMedia,
                    )
              : null,
          icon: const Icon(Icons.sync),
          label: const Text('Re-sync to markers'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: selectedMedia.isEmpty ? null : onAddImagePoint,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add image point'),
            ),
            OutlinedButton.icon(
              onPressed: beatMap == null ? null : onAddMarker,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add marker'),
            ),
            OutlinedButton.icon(
              onPressed: selectedMarker == null ? null : onDeleteMarker,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete selected'),
            ),
            OutlinedButton.icon(
              onPressed: canEditMarkers ? onDeleteMarkerAtCurrentPoint : null,
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Delete at playhead'),
            ),
            OutlinedButton.icon(
              onPressed: canEditMarkers ? onClearMarkers : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear markers'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          selectedMedia.isEmpty
              ? 'Queue images from the library to place them at the playhead.'
              : 'Manual points place queued images at the playhead. Auto-sync still uses markers.',
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(eventStatusText, style: context.textTheme.bodyMedium),
      ],
    );
  }
}

String _clipDurationLabel(VideoTemplate template) {
  final seconds = template.defaultSlideDuration.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(seconds >= 2 ? 0 : 1)}s clips';
}
