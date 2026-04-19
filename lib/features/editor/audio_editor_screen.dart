import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioEditorScreen extends ConsumerWidget {
  const AudioEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final timelineState = ref.watch(timelineViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);
    final eventState = ref.watch(eventSystemViewModelProvider);

    final resolvedBeatMap = _resolvedBeatMap(
      beatMapState: beatMapState,
      timelineState: timelineState,
      playbackState: playbackState,
    );
    final project = timelineState.asData?.value.project;
    final playback = playbackState.asData?.value;
    final events = eventState.asData?.value.events ?? const [];

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
                      ),
                    ),
                  ],
                )
              else ...[
                _MainEditorColumn(
                  beatMap: resolvedBeatMap,
                  project: project,
                  playback: playback,
                ),
                const SizedBox(height: 24),
                _EditorSidePanel(
                  beatMap: resolvedBeatMap,
                  project: project,
                  playback: playback,
                  eventState: eventState,
                  eventsCount: events.length,
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
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _PreviewCard(beatMap: beatMap, project: project, playback: playback),
        const SizedBox(height: 24),
        _TransportControls(hasBeatMap: beatMap != null, playback: playback),
        const SizedBox(height: 24),
        _TimelineWorkspace(
          beatMap: beatMap,
          project: project,
          playback: playback,
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.beatMap,
    required this.project,
    required this.playback,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ColoredBox(color: context.colors.surfaceContainerHighest),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      beatMap == null ? 'Awaiting beat map' : 'Live preview',
                    ),
                  ),
                  const Spacer(),
                  Align(
                    child: Icon(
                      beatMap == null
                          ? Icons.movie_outlined
                          : Icons.play_circle,
                      size: 72,
                      color: context.colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project?.name ?? 'Picture To Videos Project',
                              style: context.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              beatMap == null
                                  ? 'Import audio, build the beat map, and return here for beat-aware preview.'
                                  : '${beatMap!.beats.length} beats ready • ${beatMap!.bpm.toStringAsFixed(1)} BPM',
                              style: context.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _formatDuration(playback?.currentTime ?? Duration.zero),
                        style: context.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds:$millis';
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({required this.hasBeatMap, required this.playback});

  final bool hasBeatMap;
  final PlaybackState? playback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: hasBeatMap
                  ? () => ref
                        .read(playbackViewModelProvider.notifier)
                        .step(const Duration(seconds: -10))
                  : null,
              icon: const Icon(Icons.replay_10),
            ),
            FilledButton.icon(
              onPressed: hasBeatMap
                  ? () {
                      if (playback?.isPlaying ?? false) {
                        ref.read(playbackViewModelProvider.notifier).pause();
                      } else {
                        ref.read(playbackViewModelProvider.notifier).play();
                      }
                    }
                  : null,
              icon: Icon(
                playback?.isPlaying ?? false ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(playback?.isPlaying ?? false ? 'Pause' : 'Play'),
            ),
            IconButton.filledTonal(
              onPressed: hasBeatMap
                  ? () => ref
                        .read(playbackViewModelProvider.notifier)
                        .step(const Duration(seconds: 10))
                  : null,
              icon: const Icon(Icons.forward_10),
            ),
            OutlinedButton.icon(
              onPressed: hasBeatMap
                  ? () => ref
                        .read(playbackViewModelProvider.notifier)
                        .seek(Duration.zero)
                  : null,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset playhead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineWorkspace extends StatelessWidget {
  const _TimelineWorkspace({
    required this.beatMap,
    required this.project,
    required this.playback,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineHeader(
              beatMap: beatMap,
              project: project,
              playback: playback,
            ),
            const SizedBox(height: 24),
            if (beatMap == null)
              _EditorEmptyState()
            else ...[
              _BeatMarkerRow(beatMap: beatMap!),
              const SizedBox(height: 24),
              if (project != null && project!.tracks.isNotEmpty)
                for (final track in project!.tracks) ...[
                  _TrackCanvasRow(track: track, beatMap: beatMap!),
                  const SizedBox(height: 16),
                ]
              else
                _SuggestedTrackCanvas(beatMap: beatMap!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
    required this.beatMap,
    required this.project,
    required this.playback,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Timeline workspace', style: context.textTheme.titleLarge),
        Chip(
          label: Text(
            beatMap == null
                ? 'No sync'
                : '${beatMap!.averageBeatInterval.inMilliseconds} ms interval',
          ),
        ),
        Chip(
          label: Text(
            project == null
                ? 'No project timeline'
                : '${project!.tracks.length} tracks',
          ),
        ),
        Chip(label: Text('Next beat ${playback?.nextBeatIndex ?? 0}')),
      ],
    );
  }
}

class _BeatMarkerRow extends StatelessWidget {
  const _BeatMarkerRow({required this.beatMap});

  final BeatMap beatMap;

  @override
  Widget build(BuildContext context) {
    final visibleBeats = beatMap.beats.take(12).toList(growable: false);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final beat in visibleBeats) ...[
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 2,
                  height: 20 + (beat.strength * 12),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TrackCanvasRow extends StatelessWidget {
  const _TrackCanvasRow({required this.track, required this.beatMap});

  final TimelineTrack track;
  final BeatMap beatMap;

  @override
  Widget build(BuildContext context) {
    final eventCount = track.events.isEmpty ? 1 : track.events.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(track.name, style: context.textTheme.titleMedium),
              ),
              Chip(label: Text('$eventCount events')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final beat in beatMap.beats.take(12)) ...[
                Expanded(
                  child: Container(
                    height: 28 + ((beat.strength * 10) % 36),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final event in track.events.take(6))
                Chip(
                  label: Text(
                    '${event.type} @ ${event.time.inMilliseconds} ms',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestedTrackCanvas extends StatelessWidget {
  const _SuggestedTrackCanvas({required this.beatMap});

  final BeatMap beatMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline ready for track placement',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Beat markers are loaded. Build the project timeline from the import flow to populate tracks here automatically.',
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final beat in beatMap.beats.take(12)) ...[
                Expanded(
                  child: Container(
                    height: 20 + ((beat.strength * 10) % 32),
                    decoration: BoxDecoration(
                      color: context.colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 36,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Editor waiting for beat-aware data',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Return to the import flow, run beat detection, build the beat map, then come back here for preview and timeline editing.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToImportAudio(),
                  icon: const Icon(Icons.audio_file_outlined),
                  label: const Text('Go to import'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToLibrary(),
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Browse library'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSidePanel extends StatelessWidget {
  const _EditorSidePanel({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.eventState,
    required this.eventsCount,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final AsyncValue<EventSystemState> eventState;
  final int eventsCount;

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
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
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
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _eventStatusText(eventState),
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _eventStatusText(AsyncValue<EventSystemState> eventState) {
    return switch (eventState) {
      AsyncLoading<EventSystemState>() => 'Preparing event dispatch state.',
      AsyncError<EventSystemState>(:final error) => error.toString(),
      AsyncData<EventSystemState>(:final value) when value.hasEvents =>
        'Next event index ${value.nextEventIndex} with ${value.executions.length} executions recorded.',
      _ => 'Load marker events to see beat-triggered actions here.',
    };
  }
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
