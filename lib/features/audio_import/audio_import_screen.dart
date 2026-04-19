import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_state.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_state.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/preprocessing/preprocessing_state.dart';
import 'package:picturestovideos/features/preprocessing/preprocessing_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioImportScreen extends ConsumerWidget {
  const AudioImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(audioImportViewModelProvider);
    final analysisState = ref.watch(audioAnalysisViewModelProvider);
    final beatState = ref.watch(beatDetectionViewModelProvider);
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final eventState = ref.watch(eventSystemViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);
    final preprocessingState = ref.watch(preprocessingViewModelProvider);
    final timelineState = ref.watch(timelineViewModelProvider);

    ref.listen(playbackViewModelProvider, (_, next) {
      final playback = next.value;
      if (playback == null || !playback.hasBeatMap) {
        return;
      }

      ref
          .read(eventSystemViewModelProvider.notifier)
          .dispatchForPlaybackTime(playback.currentTime);
    });

    final hasImportedAudio = importState.asData?.value.hasAudio ?? false;

    return AppShellScaffold(
      currentRoute: AppRoutes.importAudio,
      title: 'Import audio',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: hasImportedAudio
                ? () => context.appNavigator.goToAudioEditor()
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open editor'),
          ),
        ),
      ],
      body: switch (importState) {
        AsyncLoading<AudioImportState>() => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<AudioImportState>(:final error) => _ImportErrorView(
          error: error,
          onRetry: () =>
              ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
        ),
        AsyncData<AudioImportState>(:final value) => _AudioImportView(
          state: value,
          analysisState: analysisState,
          beatState: beatState,
          beatMapState: beatMapState,
          eventState: eventState,
          playbackState: playbackState,
          preprocessingState: preprocessingState,
          timelineState: timelineState,
          onImportPressed: () =>
              ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
          onAnalyzePressed: value.audioData == null
              ? null
              : () => ref
                    .read(audioAnalysisViewModelProvider.notifier)
                    .analyzeAudio(value.audioData!),
          onDetectBeatsPressed: switch (analysisState) {
            AsyncData<AudioAnalysisState>(:final value)
                when value.frames.isNotEmpty =>
              () => ref
                  .read(beatDetectionViewModelProvider.notifier)
                  .detectBeats(value.frames),
            _ => null,
          },
          onBuildBeatMapPressed: switch (beatState) {
            AsyncData<BeatDetectionState>(:final value)
                when value.beats.isNotEmpty =>
              () => ref
                  .read(beatMapViewModelProvider.notifier)
                  .buildBeatMap(value.beats),
            _ => null,
          },
          onLoadPlaybackPressed: switch (beatMapState) {
            AsyncData<BeatMapState>(:final value) when value.hasBeatMap =>
              () => ref
                  .read(playbackViewModelProvider.notifier)
                  .loadBeatMap(value.beatMap),
            _ => null,
          },
          onLoadEventsPressed: switch (beatMapState) {
            AsyncData<BeatMapState>(:final value) when value.hasBeatMap =>
              () => ref
                  .read(eventSystemViewModelProvider.notifier)
                  .loadMarkerEventsFromBeatMap(value.beatMap),
            _ => null,
          },
          onPlaybackStepPressed: () => ref
              .read(playbackViewModelProvider.notifier)
              .step(const Duration(milliseconds: 100)),
          onPlaybackSeekPressed: () =>
              ref.read(playbackViewModelProvider.notifier).seek(Duration.zero),
          onBuildTimelinePressed: switch ((beatMapState, eventState)) {
            (
              AsyncData<BeatMapState>(value: final beatMapValue),
              AsyncData<EventSystemState>(value: final eventValue),
            )
                when beatMapValue.hasBeatMap && eventValue.hasEvents =>
              () => ref
                  .read(timelineViewModelProvider.notifier)
                  .buildProjectTimeline(
                    beatMap: beatMapValue.beatMap,
                    events: eventValue.events,
                  ),
            _ => null,
          },
          onSaveCachePressed: switch ((value.audioData, beatMapState)) {
            (
              final AudioData audioData?,
              AsyncData<BeatMapState>(value: final beatMapValue),
            )
                when beatMapValue.hasBeatMap =>
              () => ref
                  .read(preprocessingViewModelProvider.notifier)
                  .saveBeatMap(
                    audioData: audioData,
                    beatMap: beatMapValue.beatMap,
                  ),
            _ => null,
          },
          onLoadCachePressed: value.audioData == null
              ? null
              : () => ref
                    .read(preprocessingViewModelProvider.notifier)
                    .loadCachedBeatMap(value.audioData!),
        ),
      },
    );
  }
}

class _AudioImportView extends StatelessWidget {
  const _AudioImportView({
    required this.state,
    required this.analysisState,
    required this.beatState,
    required this.beatMapState,
    required this.eventState,
    required this.playbackState,
    required this.preprocessingState,
    required this.timelineState,
    required this.onImportPressed,
    required this.onAnalyzePressed,
    required this.onDetectBeatsPressed,
    required this.onBuildBeatMapPressed,
    required this.onLoadPlaybackPressed,
    required this.onLoadEventsPressed,
    required this.onPlaybackStepPressed,
    required this.onPlaybackSeekPressed,
    required this.onBuildTimelinePressed,
    required this.onSaveCachePressed,
    required this.onLoadCachePressed,
  });

  final AudioImportState state;
  final AsyncValue<AudioAnalysisState> analysisState;
  final AsyncValue<BeatDetectionState> beatState;
  final AsyncValue<BeatMapState> beatMapState;
  final AsyncValue<EventSystemState> eventState;
  final AsyncValue<PlaybackState> playbackState;
  final AsyncValue<PreprocessingState> preprocessingState;
  final AsyncValue<TimelineState> timelineState;
  final VoidCallback onImportPressed;
  final VoidCallback? onAnalyzePressed;
  final VoidCallback? onDetectBeatsPressed;
  final VoidCallback? onBuildBeatMapPressed;
  final VoidCallback? onLoadPlaybackPressed;
  final VoidCallback? onLoadEventsPressed;
  final VoidCallback onPlaybackStepPressed;
  final VoidCallback onPlaybackSeekPressed;
  final VoidCallback? onBuildTimelinePressed;
  final VoidCallback? onSaveCachePressed;
  final VoidCallback? onLoadCachePressed;

  @override
  Widget build(BuildContext context) {
    final progress = _PipelineProgress.fromStates(
      importState: state,
      analysisState: analysisState,
      beatState: beatState,
      beatMapState: beatMapState,
      eventState: eventState,
      playbackState: playbackState,
      timelineState: timelineState,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;
        final contentPadding = EdgeInsets.all(isWide ? 32 : 24);

        return ListView(
          padding: contentPadding,
          children: [
            Text('Import audio', style: context.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Bring WAV tracks into the workspace, inspect the waveform, and walk them through beat analysis.',
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _PrimaryColumn(
                      state: state,
                      progress: progress,
                      onImportPressed: onImportPressed,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: _SidebarColumn(
                      state: state,
                      progress: progress,
                      analysisState: analysisState,
                      beatState: beatState,
                      beatMapState: beatMapState,
                      eventState: eventState,
                      playbackState: playbackState,
                      preprocessingState: preprocessingState,
                      timelineState: timelineState,
                      onAnalyzePressed: onAnalyzePressed,
                      onDetectBeatsPressed: onDetectBeatsPressed,
                      onBuildBeatMapPressed: onBuildBeatMapPressed,
                      onLoadPlaybackPressed: onLoadPlaybackPressed,
                      onLoadEventsPressed: onLoadEventsPressed,
                      onPlaybackStepPressed: onPlaybackStepPressed,
                      onPlaybackSeekPressed: onPlaybackSeekPressed,
                      onBuildTimelinePressed: onBuildTimelinePressed,
                      onSaveCachePressed: onSaveCachePressed,
                      onLoadCachePressed: onLoadCachePressed,
                    ),
                  ),
                ],
              )
            else ...[
              _PrimaryColumn(
                state: state,
                progress: progress,
                onImportPressed: onImportPressed,
              ),
              const SizedBox(height: 24),
              _SidebarColumn(
                state: state,
                progress: progress,
                analysisState: analysisState,
                beatState: beatState,
                beatMapState: beatMapState,
                eventState: eventState,
                playbackState: playbackState,
                preprocessingState: preprocessingState,
                timelineState: timelineState,
                onAnalyzePressed: onAnalyzePressed,
                onDetectBeatsPressed: onDetectBeatsPressed,
                onBuildBeatMapPressed: onBuildBeatMapPressed,
                onLoadPlaybackPressed: onLoadPlaybackPressed,
                onLoadEventsPressed: onLoadEventsPressed,
                onPlaybackStepPressed: onPlaybackStepPressed,
                onPlaybackSeekPressed: onPlaybackSeekPressed,
                onBuildTimelinePressed: onBuildTimelinePressed,
                onSaveCachePressed: onSaveCachePressed,
                onLoadCachePressed: onLoadCachePressed,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PrimaryColumn extends StatelessWidget {
  const _PrimaryColumn({
    required this.state,
    required this.progress,
    required this.onImportPressed,
  });

  final AudioImportState state;
  final _PipelineProgress progress;
  final VoidCallback onImportPressed;

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
                Icon(
                  state.hasAudio
                      ? Icons.audio_file
                      : Icons.cloud_upload_outlined,
                  size: 32,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  state.hasAudio
                      ? 'Audio ready for analysis'
                      : 'Drop audio into the workspace',
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.hasAudio
                      ? 'The imported track is decoded and ready for the next pipeline steps.'
                      : 'Start with a WAV file. This stage prepares the waveform preview, beat analysis, and editor handoff.',
                  style: context.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onImportPressed,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choose audio file'),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Drag and drop soon'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('WAV decoding live')),
                    Chip(label: Text('Waveform preview ready')),
                    Chip(label: Text('Beat analysis pipeline connected')),
                  ],
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current process',
                        style: context.textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      progress.percentLabel,
                      style: context.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(progress.label, style: context.textTheme.bodyMedium),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress.value),
                const SizedBox(height: 24),
                _WaveformPreview(audioData: state.audioData),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _TrackDetailsCard(state: state),
      ],
    );
  }
}

class _SidebarColumn extends StatelessWidget {
  const _SidebarColumn({
    required this.state,
    required this.progress,
    required this.analysisState,
    required this.beatState,
    required this.beatMapState,
    required this.eventState,
    required this.playbackState,
    required this.preprocessingState,
    required this.timelineState,
    required this.onAnalyzePressed,
    required this.onDetectBeatsPressed,
    required this.onBuildBeatMapPressed,
    required this.onLoadPlaybackPressed,
    required this.onLoadEventsPressed,
    required this.onPlaybackStepPressed,
    required this.onPlaybackSeekPressed,
    required this.onBuildTimelinePressed,
    required this.onSaveCachePressed,
    required this.onLoadCachePressed,
  });

  final AudioImportState state;
  final _PipelineProgress progress;
  final AsyncValue<AudioAnalysisState> analysisState;
  final AsyncValue<BeatDetectionState> beatState;
  final AsyncValue<BeatMapState> beatMapState;
  final AsyncValue<EventSystemState> eventState;
  final AsyncValue<PlaybackState> playbackState;
  final AsyncValue<PreprocessingState> preprocessingState;
  final AsyncValue<TimelineState> timelineState;
  final VoidCallback? onAnalyzePressed;
  final VoidCallback? onDetectBeatsPressed;
  final VoidCallback? onBuildBeatMapPressed;
  final VoidCallback? onLoadPlaybackPressed;
  final VoidCallback? onLoadEventsPressed;
  final VoidCallback onPlaybackStepPressed;
  final VoidCallback onPlaybackSeekPressed;
  final VoidCallback? onBuildTimelinePressed;
  final VoidCallback? onSaveCachePressed;
  final VoidCallback? onLoadCachePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RecentTracksCard(state: state),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pipeline actions', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onAnalyzePressed,
                  child: const Text('Run energy analysis'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onDetectBeatsPressed,
                  child: const Text('Detect beats'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onBuildBeatMapPressed,
                  child: const Text('Build beat map'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onBuildTimelinePressed,
                  child: const Text('Build timeline'),
                ),
                const SizedBox(height: 24),
                Text('Status', style: context.textTheme.titleMedium),
                const SizedBox(height: 12),
                _StageStatusTile(
                  title: 'Import',
                  status: state.hasAudio ? 'Ready' : 'Waiting',
                  detail: progress.importDetail,
                ),
                _StageStatusTile(
                  title: 'Analysis',
                  status: _statusLabel(
                    analysisState,
                    hasData: _hasAnalysisData,
                  ),
                  detail: _analysisDetail(analysisState),
                ),
                _StageStatusTile(
                  title: 'Beat map',
                  status: _statusLabel(beatMapState, hasData: _hasBeatMapData),
                  detail: _beatMapDetail(beatMapState),
                ),
                _StageStatusTile(
                  title: 'Timeline',
                  status: _statusLabel(
                    timelineState,
                    hasData: _hasTimelineData,
                  ),
                  detail: _timelineDetail(timelineState),
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
                Text('Advanced tools', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: onLoadPlaybackPressed,
                      child: const Text('Load playback'),
                    ),
                    OutlinedButton(
                      onPressed: onLoadEventsPressed,
                      child: const Text('Load events'),
                    ),
                    OutlinedButton(
                      onPressed: onPlaybackStepPressed,
                      child: const Text('Step +100 ms'),
                    ),
                    OutlinedButton(
                      onPressed: onPlaybackSeekPressed,
                      child: const Text('Reset playback'),
                    ),
                    OutlinedButton(
                      onPressed: onSaveCachePressed,
                      child: const Text('Save cache'),
                    ),
                    OutlinedButton(
                      onPressed: onLoadCachePressed,
                      child: const Text('Load cache'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _StageStatusTile(
                  title: 'Beat detection',
                  status: _statusLabel(beatState, hasData: _hasBeatData),
                  detail: _beatDetail(beatState),
                ),
                _StageStatusTile(
                  title: 'Events',
                  status: _statusLabel(eventState, hasData: _hasEventData),
                  detail: _eventDetail(eventState),
                ),
                _StageStatusTile(
                  title: 'Playback',
                  status: _statusLabel(
                    playbackState,
                    hasData: _hasPlaybackData,
                  ),
                  detail: _playbackDetail(playbackState),
                ),
                _StageStatusTile(
                  title: 'Cache',
                  status: _statusLabel(
                    preprocessingState,
                    hasData: _hasPreprocessingData,
                  ),
                  detail: _preprocessingDetail(preprocessingState),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel<T>(
    AsyncValue<T> state, {
    required bool Function(T value) hasData,
  }) {
    return switch (state) {
      AsyncLoading<T>() => 'Loading',
      AsyncError<T>() => 'Error',
      AsyncData<T>(:final value) when hasData(value) => 'Ready',
      _ => 'Waiting',
    };
  }

  static bool _hasAnalysisData(AudioAnalysisState value) =>
      value.frames.isNotEmpty;
  static bool _hasBeatData(BeatDetectionState value) => value.beats.isNotEmpty;
  static bool _hasBeatMapData(BeatMapState value) => value.hasBeatMap;
  static bool _hasEventData(EventSystemState value) => value.hasEvents;
  static bool _hasPlaybackData(PlaybackState value) => value.hasBeatMap;
  static bool _hasPreprocessingData(PreprocessingState value) =>
      value.hasCachedBeatMap;
  static bool _hasTimelineData(TimelineState value) => value.hasProject;

  String _analysisDetail(AsyncValue<AudioAnalysisState> state) {
    return switch (state) {
      AsyncLoading<AudioAnalysisState>() => 'Generating frame energy data.',
      AsyncError<AudioAnalysisState>(:final error) => error.toString(),
      AsyncData<AudioAnalysisState>(:final value)
          when value.frames.isNotEmpty =>
        '${value.frameCount} frames ready',
      _ => 'Import audio to unlock analysis.',
    };
  }

  String _beatDetail(AsyncValue<BeatDetectionState> state) {
    return switch (state) {
      AsyncLoading<BeatDetectionState>() => 'Scanning for beat candidates.',
      AsyncError<BeatDetectionState>(:final error) => error.toString(),
      AsyncData<BeatDetectionState>(:final value) when value.beats.isNotEmpty =>
        '${value.beatCount} beats detected',
      _ => 'Run analysis first.',
    };
  }

  String _beatMapDetail(AsyncValue<BeatMapState> state) {
    return switch (state) {
      AsyncLoading<BeatMapState>() => 'Mapping beat timings.',
      AsyncError<BeatMapState>(:final error) => error.toString(),
      AsyncData<BeatMapState>(:final value) when value.hasBeatMap =>
        '${value.beatMap.bpm.toStringAsFixed(1)} BPM estimate',
      _ => 'Detect beats to build the map.',
    };
  }

  String _eventDetail(AsyncValue<EventSystemState> state) {
    return switch (state) {
      AsyncLoading<EventSystemState>() => 'Preparing marker events.',
      AsyncError<EventSystemState>(:final error) => error.toString(),
      AsyncData<EventSystemState>(:final value) when value.hasEvents =>
        '${value.events.length} events scheduled',
      _ => 'Load a beat map to create events.',
    };
  }

  String _playbackDetail(AsyncValue<PlaybackState> state) {
    return switch (state) {
      AsyncLoading<PlaybackState>() => 'Syncing playback state.',
      AsyncError<PlaybackState>(:final error) => error.toString(),
      AsyncData<PlaybackState>(:final value) when value.hasBeatMap =>
        '${value.currentTime.inMilliseconds} ms current position',
      _ => 'Load playback after beat map creation.',
    };
  }

  String _preprocessingDetail(AsyncValue<PreprocessingState> state) {
    return switch (state) {
      AsyncLoading<PreprocessingState>() => 'Updating cache state.',
      AsyncError<PreprocessingState>(:final error) => error.toString(),
      AsyncData<PreprocessingState>(:final value) when value.hasCachedBeatMap =>
        value.lastAction,
      AsyncData<PreprocessingState>(:final value) => value.lastAction,
      _ => 'Cache is idle.',
    };
  }

  String _timelineDetail(AsyncValue<TimelineState> state) {
    return switch (state) {
      AsyncLoading<TimelineState>() => 'Building project timeline.',
      AsyncError<TimelineState>(:final error) => error.toString(),
      AsyncData<TimelineState>(:final value) when value.hasProject =>
        '${value.project!.tracks.length} timeline tracks ready',
      _ => 'Load events to build the timeline.',
    };
  }
}

class _TrackDetailsCard extends StatelessWidget {
  const _TrackDetailsCard({required this.state});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasAudio || state.source == null || state.audioData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No track imported yet. Choose a WAV file to view metadata and waveform details.',
            style: context.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final audioData = state.audioData!;
    final source = state.source!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _MetricTile(label: 'File', value: source.fileName),
            _MetricTile(
              label: 'Sample rate',
              value: '${audioData.sampleRate} Hz',
            ),
            _MetricTile(
              label: 'Duration',
              value: _formatDuration(audioData.duration),
            ),
            _MetricTile(label: 'Channels', value: '${audioData.channelCount}'),
            _MetricTile(label: 'Samples', value: '${audioData.samples.length}'),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = duration.inMilliseconds
        .remainder(1000)
        .toString()
        .padLeft(3, '0');

    return '$minutes:$seconds.$millis';
  }
}

class _WaveformPreview extends StatelessWidget {
  const _WaveformPreview({required this.audioData});

  final AudioData? audioData;

  @override
  Widget build(BuildContext context) {
    if (audioData == null || audioData!.samples.isEmpty) {
      return Card.outlined(
        child: SizedBox(
          height: 184,
          child: Center(
            child: Text(
              'Waveform preview appears after import.',
              style: context.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final bars = _buildBars(audioData!.samples, 40);

    return Card.outlined(
      child: SizedBox(
        height: 184,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final barHeight in bars) ...[
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      height: barHeight,
                      width: 6,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<double> _buildBars(List<double> samples, int barCount) {
    final chunkSize = math.max(1, samples.length ~/ barCount);
    final bars = <double>[];

    for (var start = 0; start < samples.length; start += chunkSize) {
      final end = math.min(start + chunkSize, samples.length);
      var sum = 0.0;

      for (var index = start; index < end; index += 1) {
        sum += samples[index].abs();
      }

      final average = sum / (end - start);
      bars.add((average * 140).clamp(18, 120).toDouble());
    }

    if (bars.length > barCount) {
      return bars.take(barCount).toList();
    }

    while (bars.length < barCount) {
      bars.add(18);
    }

    return bars;
  }
}

class _RecentTracksCard extends StatelessWidget {
  const _RecentTracksCard({required this.state});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent tracks', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (!state.hasAudio ||
                state.source == null ||
                state.audioData == null)
              Text(
                'Imported tracks from this session will appear here.',
                style: context.textTheme.bodyLarge,
              )
            else
              Card.outlined(
                child: ListTile(
                  leading: const Icon(Icons.graphic_eq),
                  title: Text(state.source!.fileName),
                  subtitle: Text(
                    '${state.audioData!.sampleRate} Hz • ${_formatDuration(state.audioData!.duration)} • ${state.audioData!.channelCount} channels',
                  ),
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

    return '$minutes:$seconds';
  }
}

class _StageStatusTile extends StatelessWidget {
  const _StageStatusTile({
    required this.title,
    required this.status,
    required this.detail,
  });

  final String title;
  final String status;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(detail),
      trailing: Chip(label: Text(status)),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ImportErrorView extends StatelessWidget {
  const _ImportErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 16),
                Text('Import failed', style: context.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(error.toString(), style: context.textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PipelineProgress {
  const _PipelineProgress({
    required this.value,
    required this.label,
    required this.importDetail,
  });

  final double value;
  final String label;
  final String importDetail;

  String get percentLabel => '${(value * 100).round()}%';

  factory _PipelineProgress.fromStates({
    required AudioImportState importState,
    required AsyncValue<AudioAnalysisState> analysisState,
    required AsyncValue<BeatDetectionState> beatState,
    required AsyncValue<BeatMapState> beatMapState,
    required AsyncValue<EventSystemState> eventState,
    required AsyncValue<PlaybackState> playbackState,
    required AsyncValue<TimelineState> timelineState,
  }) {
    final steps = [
      importState.hasAudio,
      analysisState.asData?.value.frames.isNotEmpty ?? false,
      beatState.asData?.value.beats.isNotEmpty ?? false,
      beatMapState.asData?.value.hasBeatMap ?? false,
      eventState.asData?.value.hasEvents ?? false,
      playbackState.asData?.value.hasBeatMap ?? false,
      timelineState.asData?.value.hasProject ?? false,
    ];

    final completeSteps = steps.where((step) => step).length;
    final value = completeSteps / steps.length;

    final label = switch ((
      analysisState,
      beatState,
      beatMapState,
      timelineState,
    )) {
      (AsyncLoading<AudioAnalysisState>(), _, _, _) =>
        'Analyzing imported audio',
      (_, AsyncLoading<BeatDetectionState>(), _, _) =>
        'Detecting beat candidates',
      (_, _, AsyncLoading<BeatMapState>(), _) => 'Building beat map',
      (_, _, _, AsyncLoading<TimelineState>()) => 'Building timeline',
      _ when timelineState.asData?.value.hasProject ?? false =>
        'Ready for editor handoff',
      _ when beatMapState.asData?.value.hasBeatMap ?? false =>
        'Beat map ready for playback and events',
      _ when importState.hasAudio => 'Audio imported and waiting for analysis',
      _ => 'Waiting for the first audio file',
    };

    final importDetail = importState.hasAudio && importState.source != null
        ? importState.source!.fileName
        : 'No audio imported';

    return _PipelineProgress(
      value: value,
      label: label,
      importDetail: importDetail,
    );
  }
}
