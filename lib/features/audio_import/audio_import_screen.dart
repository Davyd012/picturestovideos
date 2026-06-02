import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/audio_import/widgets/import_completed_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/import_empty_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/import_progress_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/pipeline_progress_sheet.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
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
    final importState = importAsync.value ?? const AudioImportState.initial();
    final analysisState = ref.watch(audioAnalysisViewModelProvider);
    final beatState = ref.watch(beatDetectionViewModelProvider);
    final beatMapState = ref.watch(beatMapViewModelProvider);
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

    return AppShellScaffold(
      currentRoute: AppRoutes.importAudio,
      title: 'Import audio',
      actions: [
        _StepIndicator(state: importState),
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
        _ => _ImportAudioBody(
          state: importState,
          frames: analysisState.asData?.value.frames ?? const [],
          beats: beatState.asData?.value.beats ?? const [],
          bpm: beatMapState.asData?.value.beatMap.bpm ?? 0,
          currentTime: playbackState.asData?.value.currentTime ?? Duration.zero,
        ),
      },
    );
  }
}

class _ImportAudioBody extends ConsumerWidget {
  const _ImportAudioBody({
    required this.state,
    required this.frames,
    required this.beats,
    required this.bpm,
    required this.currentTime,
  });

  final AudioImportState state;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final double bpm;
  final Duration currentTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: switch (state.flowState) {
        AudioImportFlowState.empty => ImportEmptyState(
          onChooseFile: () =>
              ref.read(audioImportViewModelProvider.notifier).pickAudioFile(),
          onImportFromPath: () => _showImportFromPathDialog(context, ref),
        ),
        AudioImportFlowState.pickingFile ||
        AudioImportFlowState.importing ||
        AudioImportFlowState.analyzing ||
        AudioImportFlowState.failed ||
        AudioImportFlowState.cancelled => ImportProgressState(
          state: state,
          frames: frames,
          beats: beats,
          bpm: bpm,
          currentTime: currentTime,
          onViewPipeline: () => showPipelineProgressSheet(context, state),
          onStopImport: state.isRunning
              ? () => _confirmStopImport(context, ref)
              : null,
          onStartOver: () =>
              ref.read(audioImportViewModelProvider.notifier).stopImport(),
        ),
        AudioImportFlowState.completed => ImportCompletedState(
          state: state,
          beatCount: beats.length,
          bpm: bpm,
          onGoToEditor: () => context.appNavigator.goToAudioEditor(),
          onImportAnother: () => ref
              .read(audioImportViewModelProvider.notifier)
              .importAnotherFile(),
          onViewPipeline: () => showPipelineProgressSheet(context, state),
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

  Future<void> _confirmStopImport(BuildContext context, WidgetRef ref) async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Stop import?'),
          content: const Text(
            'This will cancel the current pipeline and remove the imported track from this session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep importing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Stop and start over'),
            ),
          ],
        );
      },
    );

    if (shouldStop ?? false) {
      await ref.read(audioImportViewModelProvider.notifier).stopImport();
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.state});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    final activeIndex = switch (state.flowState) {
      AudioImportFlowState.empty => 0,
      AudioImportFlowState.pickingFile || AudioImportFlowState.importing => 1,
      AudioImportFlowState.analyzing => 2,
      AudioImportFlowState.completed => 3,
      AudioImportFlowState.failed || AudioImportFlowState.cancelled => 1,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (var index = 0; index < 4; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.circle,
                size: 8,
                color: index <= activeIndex
                    ? context.colors.primary
                    : context.colors.outlineVariant,
              ),
            ),
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
