import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/waveform_preview_card.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ImportProgressState extends StatelessWidget {
  const ImportProgressState({
    required this.state,
    required this.frames,
    required this.beats,
    required this.bpm,
    required this.currentTime,
    required this.onViewPipeline,
    required this.onStopImport,
    required this.onStartOver,
    super.key,
  });

  final AudioImportState state;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final double bpm;
  final Duration currentTime;
  final VoidCallback onViewPipeline;
  final VoidCallback? onStopImport;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final isTerminal = state.isFailure || state.isCancelled;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(state.progressLabel, style: context.textTheme.bodyLarge),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _ProgressRing(state: state),
                      const SizedBox(height: 24),
                      Text(
                        _currentStepTitle,
                        style: context.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStepDescription,
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CurrentFileCard(state: state, canRemove: !state.isRunning),
              if (state.audioData != null) ...[
                const SizedBox(height: 16),
                WaveformPreviewCard(
                  audioData: state.audioData!,
                  frames: frames,
                  beats: beats,
                  bpm: bpm,
                  currentTime: currentTime,
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: onViewPipeline,
                    icon: const Icon(Icons.timeline),
                    label: const Text('View pipeline progress'),
                  ),
                  if (isTerminal)
                    OutlinedButton.icon(
                      onPressed: onStartOver,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Start over'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: onStopImport,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop import'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _title {
    if (state.isFailure) {
      return 'Import failed';
    }
    if (state.isCancelled) {
      return 'Import cancelled';
    }
    if (state.isPickingFile) {
      return 'Choosing track';
    }
    return state.flowState == AudioImportFlowState.analyzing
        ? 'Analyzing track'
        : 'Importing track';
  }

  String get _currentStepTitle {
    final stage = state.activeStage;
    if (stage == null) {
      return state.isPickingFile ? 'Waiting for file' : 'Pipeline paused';
    }
    return state.titleForStage(stage);
  }

  String get _currentStepDescription {
    final stage = state.activeStage;
    if (stage == null) {
      return state.progressLabel;
    }
    return state.detailForStage(stage);
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.state});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progressValue;

    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: state.isRunning ? progress : null,
            strokeWidth: 8,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: context.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _CurrentFileCard extends StatelessWidget {
  const _CurrentFileCard({required this.state, required this.canRemove});

  final AudioImportState state;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final audioData = state.audioData;

    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.audio_file),
        title: Text(state.source?.fileName ?? 'No file selected'),
        subtitle: Text(
          audioData == null
              ? state.importDetail
              : '${_formatDuration(audioData.duration)} - ${audioData.sampleRate} Hz',
        ),
        trailing: canRemove ? const Icon(Icons.close) : null,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
