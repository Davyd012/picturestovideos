import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/audio_import/widgets/audio_analysis_debug_chart.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioImportScreen extends ConsumerWidget {
  const AudioImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importAsync = ref.watch(audioImportViewModelProvider);
    final analysisState = ref.watch(audioAnalysisViewModelProvider);
    final beatState = ref.watch(beatDetectionViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);

    ref.listen(playbackViewModelProvider, (_, next) {
      final playback = next.value;
      if (playback == null || !playback.hasBeatMap) {
        return;
      }

      ref
          .read(eventSystemViewModelProvider.notifier)
          .dispatchForPlaybackTime(playback.currentTime);
    });

    final importState = importAsync.value ?? const AudioImportState.initial();

    return AppShellScaffold(
      currentRoute: AppRoutes.importAudio,
      title: 'Import audio',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: importState.canOpenEditor
                ? () => context.appNavigator.goToAudioEditor()
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open editor'),
          ),
        ),
      ],
      body: switch (importAsync) {
        AsyncError<AudioImportState>(:final error) => _ImportErrorView(
          error: error,
          onRetry: () =>
              ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
        ),
        _ => _AudioImportView(
          state: importState,
          frames: analysisState.asData?.value.frames ?? const [],
          beats: beatState.asData?.value.beats ?? const [],
          currentTime: playbackState.asData?.value.currentTime ?? Duration.zero,
          onImportPressed: importState.isRunning
              ? null
              : () => ref
                    .read(audioImportViewModelProvider.notifier)
                    .pickAudioFile(),
          onImportFromPathPressed: importState.isRunning
              ? null
              : () => _showImportFromPathDialog(context, ref),
        ),
      },
    );
  }

  Future<void> _showImportFromPathDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final navigator = Navigator.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import WAV from path'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '/home/user/audio/track.wav',
              labelText: 'Absolute WAV path',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                navigator.pop();
                await ref
                    .read(audioImportViewModelProvider.notifier)
                    .importAudioFromPath(controller.text);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}

class _AudioImportView extends StatelessWidget {
  const _AudioImportView({
    required this.state,
    required this.frames,
    required this.beats,
    required this.currentTime,
    required this.onImportPressed,
    required this.onImportFromPathPressed,
  });

  final AudioImportState state;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final Duration currentTime;
  final VoidCallback? onImportPressed;
  final VoidCallback? onImportFromPathPressed;

  @override
  Widget build(BuildContext context) {
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
              'Bring WAV tracks into the workspace and let the rhythm pipeline prepare everything automatically.',
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
                      frames: frames,
                      beats: beats,
                      currentTime: currentTime,
                      onImportPressed: onImportPressed,
                      onImportFromPathPressed: onImportFromPathPressed,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: _SidebarColumn(state: state)),
                ],
              )
            else ...[
              _PrimaryColumn(
                state: state,
                frames: frames,
                beats: beats,
                currentTime: currentTime,
                onImportPressed: onImportPressed,
                onImportFromPathPressed: onImportFromPathPressed,
              ),
              const SizedBox(height: 24),
              _SidebarColumn(state: state),
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
    required this.frames,
    required this.beats,
    required this.currentTime,
    required this.onImportPressed,
    required this.onImportFromPathPressed,
  });

  final AudioImportState state;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final Duration currentTime;
  final VoidCallback? onImportPressed;
  final VoidCallback? onImportFromPathPressed;

  @override
  Widget build(BuildContext context) {
    final headline = switch ((
      state.isRunning,
      state.canOpenEditor,
      state.hasSelectedFile,
    )) {
      (true, _, _) => 'Pipeline is running',
      (_, true, _) => 'Audio ready for editor handoff',
      (_, _, true) => 'Audio selected for processing',
      _ => 'Drop audio into the workspace',
    };

    final description = switch ((
      state.isRunning,
      state.canOpenEditor,
      state.isFailure,
    )) {
      (true, _, _) => state.progressLabel,
      (_, true, _) =>
        state.warningMessage ??
            'The imported track is decoded, analyzed, and ready for the editor.',
      (_, _, true) => state.errorMessage ?? 'The import pipeline hit an error.',
      _ =>
        'Choose a WAV file and the app will decode, analyze, detect beats, and prepare the timeline automatically.',
    };

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  state.canOpenEditor
                      ? Icons.audio_file
                      : state.isRunning
                      ? Icons.graphic_eq
                      : Icons.cloud_upload_outlined,
                  size: 32,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 16),
                Text(headline, style: context.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(description, style: context.textTheme.bodyLarge),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onImportPressed,
                      icon: const Icon(Icons.folder_open),
                      label: Text(
                        state.hasSelectedFile
                            ? 'Choose another file'
                            : 'Choose audio file',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onImportFromPathPressed,
                      icon: const Icon(Icons.terminal),
                      label: const Text('Import from path'),
                    ),
                    Chip(label: Text(state.importDetail)),
                    if (state.isRunning)
                      const Chip(label: Text('Processing in background')),
                    if (state.canOpenEditor)
                      const Chip(label: Text('Editor handoff ready')),
                    if (state.hasWarning)
                      const Chip(label: Text('Playback warning')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (state.hasWarning) ...[
          const SizedBox(height: 24),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playback warning',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.warningMessage!,
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (state.isFailure && state.errorMessage != null) ...[
          const SizedBox(height: 24),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: context.colors.error),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pipeline error',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage!,
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _CurrentProcessCard(
          state: state,
          frames: frames,
          beats: beats,
          currentTime: currentTime,
        ),
        const SizedBox(height: 24),
        _TrackDetailsCard(state: state),
      ],
    );
  }
}

class _CurrentProcessCard extends StatelessWidget {
  const _CurrentProcessCard({
    required this.state,
    required this.frames,
    required this.beats,
    required this.currentTime,
  });

  final AudioImportState state;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final Duration currentTime;

  @override
  Widget build(BuildContext context) {
    final hasChartData = state.audioData != null;

    return Card(
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
                  '${(state.progressValue * 100).round()}%',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                state.progressLabel,
                key: ValueKey(state.progressLabel),
                style: context.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: state.progressValue),
              duration: const Duration(milliseconds: 350),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: state.isRunning ? value : state.progressValue,
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: hasChartData
                  ? AudioAnalysisDebugChart(
                      key: ValueKey(
                        '${state.source?.fileName}-${frames.length}-${beats.length}',
                      ),
                      audioData: state.audioData,
                      frames: frames,
                      beats: beats,
                      currentTime: currentTime,
                    )
                  : const _ChartLoadingPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarColumn extends StatelessWidget {
  const _SidebarColumn({required this.state});

  final AudioImportState state;

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
                Text('Pipeline status', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                for (final stage in AudioImportPipelineStage.values) ...[
                  _StageStatusTile(
                    title: state.titleForStage(stage),
                    detail: state.detailForStage(stage),
                    visualState: _visualStateForStage(stage),
                  ),
                  if (stage != AudioImportPipelineStage.values.last)
                    Divider(color: context.colors.outlineVariant),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  _StageVisualState _visualStateForStage(AudioImportPipelineStage stage) {
    if (state.isStageFailed(stage)) {
      return _StageVisualState.error;
    }
    if (state.isStageRunning(stage)) {
      return _StageVisualState.running;
    }
    if (state.isStageComplete(stage)) {
      return _StageVisualState.complete;
    }
    return _StageVisualState.waiting;
  }
}

class _TrackDetailsCard extends StatelessWidget {
  const _TrackDetailsCard({required this.state});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSelectedFile) {
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

    if (!state.hasAudio || state.source == null || state.audioData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Track details', style: context.textTheme.titleLarge),
              const SizedBox(height: 16),
              _MetricTile(label: 'File', value: state.source!.fileName),
              const SizedBox(height: 16),
              const _DetailsLoadingPlaceholder(),
            ],
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
            if (!state.hasSelectedFile || state.source == null)
              Text(
                'Imported tracks from this session will appear here.',
                style: context.textTheme.bodyLarge,
              )
            else
              Card.outlined(
                child: ListTile(
                  leading: Icon(
                    state.isRunning ? Icons.sync : Icons.graphic_eq,
                  ),
                  title: Text(state.source!.fileName),
                  subtitle: Text(
                    state.hasAudio && state.audioData != null
                        ? '${state.audioData!.sampleRate} Hz • ${_formatDuration(state.audioData!.duration)} • ${state.audioData!.channelCount} channels'
                        : state.progressLabel,
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

enum _StageVisualState { waiting, running, complete, error }

class _StageStatusTile extends StatelessWidget {
  const _StageStatusTile({
    required this.title,
    required this.detail,
    required this.visualState,
  });

  final String title;
  final String detail;
  final _StageVisualState visualState;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(detail),
      trailing: SizedBox(
        width: 88,
        child: switch (visualState) {
          _StageVisualState.running => const _RunningStageBadge(),
          _StageVisualState.complete => Chip(
            label: const Text('Ready'),
            backgroundColor: context.colors.primaryContainer,
          ),
          _StageVisualState.error => Chip(
            label: const Text('Error'),
            backgroundColor: context.colors.errorContainer,
          ),
          _StageVisualState.waiting => Chip(
            label: const Text('Waiting'),
            backgroundColor: context.colors.surfaceContainerHighest,
          ),
        },
      ),
    );
  }
}

class _RunningStageBadge extends StatelessWidget {
  const _RunningStageBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Running'),
        const SizedBox(height: 8),
        LinearProgressIndicator(color: context.colors.primary),
      ],
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

class _ChartLoadingPlaceholder extends StatelessWidget {
  const _ChartLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('chart-placeholder'),
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis preview', style: context.textTheme.titleLarge),
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Waveform and beat markers will appear as soon as the pipeline reaches analysis.',
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsLoadingPlaceholder extends StatelessWidget {
  const _DetailsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Sample rate, duration, and channel details will appear when decoding finishes.',
          style: context.textTheme.bodyMedium,
        ),
      ],
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: context.colors.error,
                ),
                const SizedBox(height: 16),
                Text('Import error', style: context.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
