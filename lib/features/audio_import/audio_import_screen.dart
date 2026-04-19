import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_state.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_state.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';

class AudioImportScreen extends ConsumerWidget {
  const AudioImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(audioImportViewModelProvider);
    final analysisState = ref.watch(audioAnalysisViewModelProvider);
    final beatState = ref.watch(beatDetectionViewModelProvider);
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio pipeline foundation'),
      ),
      body: switch (importState) {
        AsyncLoading<AudioImportState>() => const Center(
            child: CircularProgressIndicator(),
          ),
        AsyncError<AudioImportState>(:final error) => _AudioImportError(
            error: error,
            onRetry: () =>
                ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
          ),
        AsyncData<AudioImportState>(:final value) => _AudioImportContent(
            state: value,
            analysisState: analysisState,
            beatState: beatState,
            beatMapState: beatMapState,
            playbackState: playbackState,
            onImportPressed: () =>
                ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
            onAnalyzePressed: () {
              final audioData = value.audioData;
              if (audioData == null) {
                return;
              }

              ref
                  .read(audioAnalysisViewModelProvider.notifier)
                  .analyzeAudio(audioData);
            },
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
            onPlaybackStepPressed: () => ref
                .read(playbackViewModelProvider.notifier)
                .step(const Duration(milliseconds: 100)),
            onPlaybackSeekPressed: () => ref
                .read(playbackViewModelProvider.notifier)
                .seek(Duration.zero),
          ),
        _ => _AudioImportContent(
            state: const AudioImportState.initial(),
            analysisState: analysisState,
            beatState: beatState,
            beatMapState: beatMapState,
            playbackState: playbackState,
            onImportPressed: () =>
                ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
            onAnalyzePressed: null,
            onDetectBeatsPressed: null,
            onBuildBeatMapPressed: null,
            onLoadPlaybackPressed: null,
            onPlaybackStepPressed: () => ref
                .read(playbackViewModelProvider.notifier)
                .step(const Duration(milliseconds: 100)),
            onPlaybackSeekPressed: () => ref
                .read(playbackViewModelProvider.notifier)
                .seek(Duration.zero),
          ),
      },
    );
  }
}

class _AudioImportContent extends StatelessWidget {
  const _AudioImportContent({
    required this.state,
    required this.analysisState,
    required this.beatState,
    required this.beatMapState,
    required this.playbackState,
    required this.onImportPressed,
    required this.onAnalyzePressed,
    required this.onDetectBeatsPressed,
    required this.onBuildBeatMapPressed,
    required this.onLoadPlaybackPressed,
    required this.onPlaybackStepPressed,
    required this.onPlaybackSeekPressed,
  });

  final AudioImportState state;
  final AsyncValue<AudioAnalysisState> analysisState;
  final AsyncValue<BeatDetectionState> beatState;
  final AsyncValue<BeatMapState> beatMapState;
  final AsyncValue<PlaybackState> playbackState;
  final VoidCallback onImportPressed;
  final VoidCallback? onAnalyzePressed;
  final VoidCallback? onDetectBeatsPressed;
  final VoidCallback? onBuildBeatMapPressed;
  final VoidCallback? onLoadPlaybackPressed;
  final VoidCallback onPlaybackStepPressed;
  final VoidCallback onPlaybackSeekPressed;

  @override
  Widget build(BuildContext context) {
    final source = state.source;
    final audioData = state.audioData;

    return ListView(
      children: [
        const ListTile(
          title: Text('Import a WAV file'),
          subtitle: Text(
            'Stage 1 supports WAV decoding into normalized PCM samples.',
          ),
        ),
        Center(
          child: FilledButton(
            onPressed: onImportPressed,
            child: const Text('Choose audio file'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onAnalyzePressed,
            child: const Text('Run energy analysis'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onDetectBeatsPressed,
            child: const Text('Detect beats'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onBuildBeatMapPressed,
            child: const Text('Build beat map'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onLoadPlaybackPressed,
            child: const Text('Load playback sync'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onPlaybackStepPressed,
            child: const Text('Step +100 ms'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: onPlaybackSeekPressed,
            child: const Text('Reset playback'),
          ),
        ),
        if (source != null && audioData != null) ...[
          ListTile(
            title: const Text('File'),
            subtitle: Text(source.fileName),
          ),
          ListTile(
            title: const Text('Sample rate'),
            subtitle: Text('${audioData.sampleRate} Hz'),
          ),
          ListTile(
            title: const Text('Duration'),
            subtitle: Text(_formatDuration(audioData.duration)),
          ),
          ListTile(
            title: const Text('Channels'),
            subtitle: Text('${audioData.channelCount}'),
          ),
          ListTile(
            title: const Text('Samples'),
            subtitle: Text('${audioData.samples.length}'),
          ),
        ],
        _AudioAnalysisSection(
          audioData: audioData,
          analysisState: analysisState,
        ),
        _BeatDetectionSection(beatState: beatState),
        _BeatMapSection(beatMapState: beatMapState),
        _PlaybackSection(playbackState: playbackState),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis =
        duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');

    return '$minutes:$seconds.$millis';
  }
}

class _AudioAnalysisSection extends StatelessWidget {
  const _AudioAnalysisSection({
    required this.audioData,
    required this.analysisState,
  });

  final AudioData? audioData;
  final AsyncValue<AudioAnalysisState> analysisState;

  @override
  Widget build(BuildContext context) {
    return switch (analysisState) {
      AsyncLoading<AudioAnalysisState>() => const ListTile(
          title: Text('Stage 2: Energy analysis'),
          subtitle: Text('Analyzing frames...'),
        ),
      AsyncError<AudioAnalysisState>(:final error) => ListTile(
          title: const Text('Stage 2: Energy analysis'),
          subtitle: Text(error.toString()),
        ),
      AsyncData<AudioAnalysisState>(:final value) when value.frames.isNotEmpty =>
        Column(
          children: [
            ListTile(
              title: const Text('Stage 2: Energy analysis'),
              subtitle: Text(
                '${value.frameCount} frames, peak energy ${value.peakEnergy.toStringAsFixed(4)}',
              ),
            ),
            ListTile(
              title: const Text('Frame window'),
              subtitle: Text(
                '${value.config.frameSize} samples, hop ${value.config.hopSize}',
              ),
            ),
            ListTile(
              title: const Text('Timeline span'),
              subtitle: Text(
                '${_formatFrameTime(value.firstFrame)} -> ${_formatFrameTime(value.lastFrame)}',
              ),
            ),
          ],
        ),
      _ when audioData == null => const ListTile(
          title: Text('Stage 2: Energy analysis'),
          subtitle: Text('Import audio first.'),
        ),
      _ => const ListTile(
          title: Text('Stage 2: Energy analysis'),
          subtitle: Text('Ready to build audio frames from imported samples.'),
        ),
    };
  }

  String _formatFrameTime(AudioFrame? frame) {
    if (frame == null) {
      return 'n/a';
    }

    final seconds =
        frame.time.inMilliseconds / Duration.millisecondsPerSecond;
    return '${seconds.toStringAsFixed(3)} s';
  }
}

class _BeatDetectionSection extends StatelessWidget {
  const _BeatDetectionSection({
    required this.beatState,
  });

  final AsyncValue<BeatDetectionState> beatState;

  @override
  Widget build(BuildContext context) {
    return switch (beatState) {
      AsyncLoading<BeatDetectionState>() => const ListTile(
          title: Text('Stage 3: Beat detection'),
          subtitle: Text('Detecting beat candidates...'),
        ),
      AsyncError<BeatDetectionState>(:final error) => ListTile(
          title: const Text('Stage 3: Beat detection'),
          subtitle: Text(error.toString()),
        ),
      AsyncData<BeatDetectionState>(:final value) when value.beats.isNotEmpty =>
        Column(
          children: [
            ListTile(
              title: const Text('Stage 3: Beat detection'),
              subtitle: Text('${value.beatCount} beats detected'),
            ),
            ListTile(
              title: const Text('Detector config'),
              subtitle: Text(
                'Sensitivity ${value.config.sensitivity.toStringAsFixed(2)}, window ${value.config.movingAverageWindow}',
              ),
            ),
            ListTile(
              title: const Text('Beat span'),
              subtitle: Text(
                '${_formatBeatTime(value.firstBeat)} -> ${_formatBeatTime(value.lastBeat)}',
              ),
            ),
          ],
        ),
      _ => const ListTile(
          title: Text('Stage 3: Beat detection'),
          subtitle: Text('Run energy analysis first, then detect beats.'),
        ),
    };
  }

  String _formatBeatTime(Beat? beat) {
    if (beat == null) {
      return 'n/a';
    }

    final seconds =
        beat.time.inMilliseconds / Duration.millisecondsPerSecond;
    return '${seconds.toStringAsFixed(3)} s';
  }
}

class _BeatMapSection extends StatelessWidget {
  const _BeatMapSection({
    required this.beatMapState,
  });

  final AsyncValue<BeatMapState> beatMapState;

  @override
  Widget build(BuildContext context) {
    return switch (beatMapState) {
      AsyncLoading<BeatMapState>() => const ListTile(
          title: Text('Stage 4: Beat map'),
          subtitle: Text('Building beat map...'),
        ),
      AsyncError<BeatMapState>(:final error) => ListTile(
          title: const Text('Stage 4: Beat map'),
          subtitle: Text(error.toString()),
        ),
      AsyncData<BeatMapState>(:final value) when value.hasBeatMap => Column(
          children: [
            ListTile(
              title: const Text('Stage 4: Beat map'),
              subtitle: Text('${value.beatMap.beats.length} beats mapped'),
            ),
            ListTile(
              title: const Text('Estimated BPM'),
              subtitle: Text(value.beatMap.bpm.toStringAsFixed(2)),
            ),
            ListTile(
              title: const Text('Average beat interval'),
              subtitle: Text(
                '${value.beatMap.averageBeatInterval.inMilliseconds} ms',
              ),
            ),
          ],
        ),
      _ => const ListTile(
          title: Text('Stage 4: Beat map'),
          subtitle: Text('Detect beats first, then build a reusable beat map.'),
        ),
    };
  }
}

class _PlaybackSection extends StatelessWidget {
  const _PlaybackSection({
    required this.playbackState,
  });

  final AsyncValue<PlaybackState> playbackState;

  @override
  Widget build(BuildContext context) {
    return switch (playbackState) {
      AsyncLoading<PlaybackState>() => const ListTile(
          title: Text('Stage 5: Playback sync'),
          subtitle: Text('Preparing playback state...'),
        ),
      AsyncError<PlaybackState>(:final error) => ListTile(
          title: const Text('Stage 5: Playback sync'),
          subtitle: Text(error.toString()),
        ),
      AsyncData<PlaybackState>(:final value) when value.hasBeatMap => Column(
          children: [
            ListTile(
              title: const Text('Stage 5: Playback sync'),
              subtitle: Text(
                'Current time ${_formatPlaybackTime(value.currentTime)}, next beat index ${value.nextBeatIndex}',
              ),
            ),
            ListTile(
              title: const Text('Triggered beats'),
              subtitle: Text('${value.triggeredBeats.length} fired'),
            ),
            ListTile(
              title: const Text('Last triggered beat'),
              subtitle: Text(_formatBeatTime(value.lastTriggeredBeat)),
            ),
          ],
        ),
      _ => const ListTile(
          title: Text('Stage 5: Playback sync'),
          subtitle: Text('Build a beat map first, then load playback sync.'),
        ),
    };
  }

  String _formatPlaybackTime(Duration duration) {
    final seconds = duration.inMilliseconds / Duration.millisecondsPerSecond;
    return '${seconds.toStringAsFixed(3)} s';
  }

  String _formatBeatTime(Beat? beat) {
    if (beat == null) {
      return 'n/a';
    }

    final seconds = beat.time.inMilliseconds / Duration.millisecondsPerSecond;
    return '${seconds.toStringAsFixed(3)} s';
  }
}

class _AudioImportError extends StatelessWidget {
  const _AudioImportError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Import failed'),
          subtitle: Text(_errorMessage(error)),
        ),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  String _errorMessage(Object error) {
    if (error is AudioImportException) {
      return error.failure.message;
    }

    return error.toString();
  }
}
