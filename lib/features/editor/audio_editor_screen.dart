import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';
import 'package:picturestovideos/features/editor/editor_preview_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/editor_preview_card.dart';
import 'package:picturestovideos/features/editor/widgets/editor_timeline_workspace.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioEditorScreen extends ConsumerStatefulWidget {
  const AudioEditorScreen({super.key});

  @override
  ConsumerState<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends ConsumerState<AudioEditorScreen> {
  late final ProviderSubscription<ProjectTimeline?> _timelineSubscription;
  Timer? _previewSyncDebounce;

  @override
  void initState() {
    super.initState();
    _timelineSubscription = ref.listenManual<ProjectTimeline?>(
      timelineViewModelProvider.select((next) => next.asData?.value.project),
      (_, nextProject) {
        _schedulePreviewSync(nextProject);
      },
    );
  }

  @override
  void dispose() {
    _previewSyncDebounce?.cancel();
    _timelineSubscription.close();
    super.dispose();
  }

  void _schedulePreviewSync(ProjectTimeline? project) {
    if (project == null) {
      return;
    }

    _previewSyncDebounce?.cancel();
    _previewSyncDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }

      ref
          .read(editorPreviewViewModelProvider.notifier)
          .syncPreview(
            project,
            audioSourcePath: _audioSourcePath,
            reason: 'timeline listener',
          );
    });
  }

  String? get _audioSourcePath => ref.read(
    audioImportViewModelProvider.select(
      (next) => next.asData?.value.source?.path,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final timelineState = ref.watch(timelineViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);
    final eventState = ref.watch(eventSystemViewModelProvider);
    final importState = ref.watch(audioImportViewModelProvider);
    final mediaSelection = ref.watch(editorMediaSelectionViewModelProvider);
    final previewState = ref.watch(editorPreviewViewModelProvider);

    final resolvedBeatMap = _resolvedBeatMap(
      beatMapState: beatMapState,
      timelineState: timelineState,
      playbackState: playbackState,
    );
    final timeline = timelineState.asData?.value;
    final project = timeline?.project;
    final selectedMarker = timeline?.selectedMarker;
    final playback = playbackState.asData?.value;
    final events = eventState.asData?.value.events ?? const [];
    final audioSourcePath = importState.asData?.value.source?.path;

    return AppShellScaffold(
      currentRoute: AppRoutes.audioEditor,
      title: 'Audio editor',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: resolvedBeatMap == null
                ? null
                : () => context.appNavigator.goToDownload(),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export'),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentPadding = EdgeInsets.all(
            constraints.maxWidth >= 960 ? 32 : 24,
          );
          final showSidePanel = constraints.maxWidth >= 1180;

          return ListView(
            padding: contentPadding,
            children: [
              if (showSidePanel)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _MainEditorColumn(
                        beatMap: resolvedBeatMap,
                        project: project,
                        playback: playback,
                        audioSourcePath: audioSourcePath,
                        selectedMedia: mediaSelection.selectedMedia,
                        selectedMarker: selectedMarker,
                        events: events,
                        previewState: previewState,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _EditorSidePanel(
                        beatMap: resolvedBeatMap,
                        project: project,
                        playback: playback,
                        eventState: eventState,
                        eventsCount: events.length,
                        selectedMediaCount: mediaSelection.selectedCount,
                        selectedMedia: mediaSelection.selectedMedia,
                        selectedMarker: selectedMarker,
                      ),
                    ),
                  ],
                )
              else ...[
                _MainEditorColumn(
                  beatMap: resolvedBeatMap,
                  project: project,
                  playback: playback,
                  audioSourcePath: audioSourcePath,
                  selectedMedia: mediaSelection.selectedMedia,
                  selectedMarker: selectedMarker,
                  events: events,
                  previewState: previewState,
                ),
                const SizedBox(height: 24),
                _EditorSidePanel(
                  beatMap: resolvedBeatMap,
                  project: project,
                  playback: playback,
                  eventState: eventState,
                  eventsCount: events.length,
                  selectedMediaCount: mediaSelection.selectedCount,
                  selectedMedia: mediaSelection.selectedMedia,
                  selectedMarker: selectedMarker,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  BeatMap? _resolvedBeatMap({
    required AsyncValue<BeatMapState> beatMapState,
    required AsyncValue<TimelineState> timelineState,
    required AsyncValue<PlaybackState> playbackState,
  }) {
    final projectBeatMap = timelineState.asData?.value.project?.beatMap;
    if (projectBeatMap != null && projectBeatMap.beats.isNotEmpty) {
      return projectBeatMap;
    }

    final playbackBeatMap = playbackState.asData?.value.beatMap;
    if (playbackBeatMap != null && playbackBeatMap.beats.isNotEmpty) {
      return playbackBeatMap;
    }

    final stateBeatMap = beatMapState.asData?.value.beatMap;
    if (stateBeatMap != null && stateBeatMap.beats.isNotEmpty) {
      return stateBeatMap;
    }

    return null;
  }
}

class _MainEditorColumn extends ConsumerWidget {
  const _MainEditorColumn({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.audioSourcePath,
    required this.selectedMedia,
    required this.selectedMarker,
    required this.events,
    required this.previewState,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final String? audioSourcePath;
  final List<LibraryMediaItem> selectedMedia;
  final TimelineMarkerSelection? selectedMarker;
  final List<BeatEvent> events;
  final EditorPreviewState previewState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        EditorPreviewCard(
          beatMap: beatMap,
          project: project,
          playback: playback,
          audioSourcePath: audioSourcePath,
          previewState: previewState,
        ),
        const SizedBox(height: 24),
        _TransportControls(
          beatMap: beatMap,
          playback: playback,
          audioSourcePath: audioSourcePath,
        ),
        const SizedBox(height: 24),
        EditorTimelineWorkspace(
          beatMap: beatMap,
          project: project,
          playback: playback,
          selectedMedia: selectedMedia,
          selectedMarker: selectedMarker,
          onAddMarker: () => _addMarkerAtCurrentPoint(
            ref: ref,
            beatMap: beatMap,
            playback: playback,
            events: events,
          ),
          onDeleteSelectedMarker: () => ref
              .read(timelineViewModelProvider.notifier)
              .deleteSelectedImageMarker(),
          onMarkerSelected: (selection) => ref
              .read(timelineViewModelProvider.notifier)
              .selectImageMarker(
                time: selection.time,
                mediaId: selection.mediaId,
              ),
          onMarkerSelectionCleared: () => ref
              .read(timelineViewModelProvider.notifier)
              .clearImageMarkerSelection(),
          onCurrentPointChanged: (position) async {
            if (beatMap == null) {
              return;
            }

            await ref
                .read(playbackViewModelProvider.notifier)
                .preparePlayback(
                  beatMap: beatMap!,
                  audioSourcePath: audioSourcePath,
                );
            await ref.read(playbackViewModelProvider.notifier).seek(position);
          },
        ),
      ],
    );
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({
    required this.beatMap,
    required this.playback,
    required this.audioSourcePath,
  });

  final BeatMap? beatMap;
  final PlaybackState? playback;
  final String? audioSourcePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canControlTransport =
        beatMap != null &&
        ((playback?.hasLoadedAudioSource ?? false) ||
            (audioSourcePath != null && audioSourcePath!.isNotEmpty));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: canControlTransport
                  ? () async {
                      await _preparePlayback(ref);
                      await ref
                          .read(playbackViewModelProvider.notifier)
                          .step(const Duration(seconds: -10));
                    }
                  : null,
              icon: const Icon(Icons.replay_10),
            ),
            FilledButton.icon(
              onPressed: canControlTransport
                  ? () => _togglePlayback(ref)
                  : null,
              icon: Icon(
                playback?.isPlaying ?? false ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(playback?.isPlaying ?? false ? 'Pause' : 'Play'),
            ),
            IconButton.filledTonal(
              onPressed: canControlTransport
                  ? () async {
                      await _preparePlayback(ref);
                      await ref
                          .read(playbackViewModelProvider.notifier)
                          .step(const Duration(seconds: 10));
                    }
                  : null,
              icon: const Icon(Icons.forward_10),
            ),
            OutlinedButton.icon(
              onPressed: canControlTransport
                  ? () async {
                      await _preparePlayback(ref);
                      await ref
                          .read(playbackViewModelProvider.notifier)
                          .seek(Duration.zero);
                    }
                  : null,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset playhead'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preparePlayback(WidgetRef ref) async {
    if (beatMap == null) {
      return;
    }

    await ref
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(beatMap: beatMap!, audioSourcePath: audioSourcePath);
  }

  Future<void> _togglePlayback(WidgetRef ref) async {
    await _preparePlayback(ref);
    if (playback?.isPlaying ?? false) {
      await ref.read(playbackViewModelProvider.notifier).pause();
      return;
    }

    await ref.read(playbackViewModelProvider.notifier).play();
  }
}

class _EditorSidePanel extends StatelessWidget {
  const _EditorSidePanel({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.eventState,
    required this.eventsCount,
    required this.selectedMediaCount,
    required this.selectedMedia,
    required this.selectedMarker,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final AsyncValue<EventSystemState> eventState;
  final int eventsCount;
  final int selectedMediaCount;
  final List<LibraryMediaItem> selectedMedia;
  final TimelineMarkerSelection? selectedMarker;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session status', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                _StatusRow(
                  label: 'Beat map',
                  value: beatMap == null
                      ? 'Missing'
                      : '${beatMap!.beats.length} beats',
                ),
                _StatusRow(
                  label: 'Timeline',
                  value: project == null
                      ? 'Not built'
                      : '${project!.tracks.length} tracks',
                ),
                _StatusRow(label: 'Events', value: '$eventsCount loaded'),
                _StatusRow(
                  label: 'Triggered beats',
                  value: '${playback?.triggeredBeats.length ?? 0}',
                ),
                _StatusRow(
                  label: 'Images queued',
                  value: '$selectedMediaCount items',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _EditorToolsCard(
          beatMap: beatMap,
          project: project,
          playback: playback,
          eventState: eventState,
          selectedMedia: selectedMedia,
          selectedMarker: selectedMarker,
        ),
      ],
    );
  }
}

class _EditorToolsCard extends ConsumerWidget {
  const _EditorToolsCard({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.eventState,
    required this.selectedMedia,
    required this.selectedMarker,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final AsyncValue<EventSystemState> eventState;
  final List<LibraryMediaItem> selectedMedia;
  final TimelineMarkerSelection? selectedMarker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = eventState.asData?.value.events ?? const <BeatEvent>[];
    final canAutoSync = beatMap != null && selectedMedia.isNotEmpty;
    final canAddMarker = beatMap != null;
    final canDeleteMarker = selectedMarker != null;
    final hasMediaTrack =
        project?.tracks.any((track) => track.id == 'track-media') ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editor tools', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Chip(
                  label: Text(
                    beatMap == null ? 'Sync inactive' : 'Sync active',
                  ),
                ),
                Chip(
                  label: Text(
                    playback?.isPlaying ?? false ? 'Playing' : 'Paused',
                  ),
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
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                hasMediaTrack
                    ? 'Re-sync images to markers'
                    : 'Auto-sync images to markers',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: canAddMarker
                      ? () => _addMarkerAtCurrentPoint(
                          ref: ref,
                          beatMap: beatMap,
                          playback: playback,
                          events: events,
                        )
                      : null,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add marker'),
                ),
                OutlinedButton.icon(
                  onPressed: canDeleteMarker
                      ? () => ref
                            .read(timelineViewModelProvider.notifier)
                            .deleteSelectedImageMarker()
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete marker'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              selectedMedia.isEmpty
                  ? 'Queue images from the library to generate marker-synced clips.'
                  : 'Image clips start on timeline markers.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              _editorEventStatusText(eventState),
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

void _addMarkerAtCurrentPoint({
  required WidgetRef ref,
  required BeatMap? beatMap,
  required PlaybackState? playback,
  required List<BeatEvent> events,
}) {
  if (beatMap == null) {
    return;
  }

  ref
      .read(timelineViewModelProvider.notifier)
      .addImageMarkerAt(
        time: playback?.currentTime ?? Duration.zero,
        beatMap: beatMap,
        fallbackMarkerEvents: events,
      );
}

String _editorEventStatusText(AsyncValue<EventSystemState> eventState) {
  return switch (eventState) {
    AsyncLoading<EventSystemState>() => 'Preparing event dispatch state.',
    AsyncError<EventSystemState>(:final error) => error.toString(),
    AsyncData<EventSystemState>(:final value) when value.hasEvents =>
      'Next event index ${value.nextEventIndex} with ${value.executions.length} executions recorded.',
    _ => 'Load markers to see timeline-triggered actions here.',
  };
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
  }
}
