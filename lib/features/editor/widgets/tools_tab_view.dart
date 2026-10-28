import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/pacing_suggestion_summary.dart';
import 'package:picturestovideos/core/timeline/application/build_project_timeline_use_case.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/features/projects/saved_projects_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/pacing_selector.dart';
import 'package:picturestovideos/features/editor/widgets/music_settings_card.dart';
import 'package:picturestovideos/features/editor/widgets/video_template_selector.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

class ToolsTabView extends ConsumerWidget {
  const ToolsTabView({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.selectedTemplate,
    required this.selectedMedia,
    required this.selectedImageFits,
    required this.selectedMarker,
    required this.events,
    required this.eventStatusText,
    required this.audioDuration,
    required this.onAddMarker,
    required this.onAddImagePoint,
    required this.onDeleteMarker,
    required this.onDeleteMarkerAtCurrentPoint,
    required this.onClearMarkers,
    this.renderCapabilities,
    this.gateRenderCapabilities = false,
    this.capabilityProbeFailed = false,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final VideoTemplate selectedTemplate;
  final List<LibraryMediaItem> selectedMedia;
  final Map<String, VideoTemplateImageFit> selectedImageFits;
  final TimelineMarkerSelection? selectedMarker;
  final List<BeatEvent> events;
  final String eventStatusText;
  final Duration? audioDuration;
  final VoidCallback onAddMarker;
  final VoidCallback onAddImagePoint;
  final VoidCallback onDeleteMarker;
  final VoidCallback onDeleteMarkerAtCurrentPoint;
  final VoidCallback onClearMarkers;
  final RenderCapabilities? renderCapabilities;
  final bool gateRenderCapabilities;
  final bool capabilityProbeFailed;

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
    final pacingEstimate = canAutoSync && project != null
        ? ref
              .read(buildProjectTimelineUseCaseProvider)
              .call(
                beatMap: beatMap!,
                events: events,
                selectedMedia: selectedMedia,
                selectedImageFits: selectedImageFits,
                template: selectedTemplate,
                previousProject: project!,
                audioDuration: project!.audioDuration ?? audioDuration,
                pacing: project!.pacing,
              )
        : null;
    final pacingSummary = pacingEstimate == null || project == null
        ? null
        : PacingSuggestionSummary.compare(project!, pacingEstimate);
    final committedClipCount =
        project?.tracks
            .where((track) => track.id == 'track-media')
            .expand((track) => track.events)
            .where((event) => event.payload is MediaTrackClipPayload)
            .length ??
        0;
    final templateClipCount = selectedMedia.length > committedClipCount
        ? selectedMedia.length
        : committedClipCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed:
              project == null ||
                  ref.watch(savedProjectsViewModelProvider).isLoading
              ? null
              : () async {
                  final saved = await ref
                      .read(savedProjectsViewModelProvider.notifier)
                      .saveCurrent();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        saved
                            ? context.l10n.projectSaved
                            : context.l10n.projectSaveFailed,
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.save_outlined),
          label: Text(context.l10n.saveProject),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VideoTemplateSelector(
                  selectedTemplate: selectedTemplate,
                  renderCapabilities: renderCapabilities,
                  gateRenderCapabilities: gateRenderCapabilities,
                  capabilityProbeFailed: capabilityProbeFailed,
                  clipCount: templateClipCount,
                  onTemplateSelected: ref
                      .read(timelineViewModelProvider.notifier)
                      .templateSelected,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VideoTemplateAspectRatio>(
                  initialValue: selectedTemplate.aspectRatio,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.aspect_ratio_outlined),
                    labelText: context.l10n.aspectRatio,
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
              ],
            ),
          ),
        ),
        if (project != null)
          PacingSelector(
            value: project!.pacing,
            duration: pacingEstimate == null
                ? null
                : _sequenceDuration(pacingEstimate),
            suggestionSummary: pacingSummary,
            hasManualEdits: project!.hasManualEdits,
            onChanged: ref
                .read(timelineViewModelProvider.notifier)
                .pacingSelected,
            onApply: canAutoSync
                ? () => ref
                      .read(timelineViewModelProvider.notifier)
                      .applyPacingSuggestion(
                        beatMap: beatMap!,
                        events: events,
                        selectedMedia: selectedMedia,
                        selectedImageFits: selectedImageFits,
                        audioDuration: project!.audioDuration ?? audioDuration,
                      )
                : null,
            onUndo: ref
                .read(timelineViewModelProvider.notifier)
                .undoPacingSuggestion,
          ),
        if (project?.audioSourcePath != null)
          MusicSettingsCard(
            mix: project!.audioMix,
            sourceDuration: project!.audioDuration,
            onChanged: (mix) async {
              ref.read(timelineViewModelProvider.notifier).audioMixChanged(mix);
              final updated = ref
                  .read(timelineViewModelProvider)
                  .asData
                  ?.value
                  .project;
              if (updated == null) return;
              try {
                await ref
                    .read(playbackViewModelProvider.notifier)
                    .preparePlayback(
                      beatMap: updated.beatMap,
                      audioSourcePath: updated.audioSourcePath,
                      audioMix: updated.audioMix,
                      videoDuration: updated.videoDuration,
                    );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.musicPlaybackFailed)),
                  );
                }
              }
            },
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

Duration? _sequenceDuration(ProjectTimeline project) {
  Duration? end;
  for (final track in project.tracks) {
    if (track.id != 'track-media') continue;
    for (final event in track.events) {
      final clip = event.payload;
      if (clip is MediaTrackClipPayload && (end == null || clip.end > end)) {
        end = clip.end;
      }
    }
  }
  return end;
}
