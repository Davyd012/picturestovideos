import 'package:flutter/material.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/pipeline_step_tile.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

Future<void> showPipelineProgressSheet(
  BuildContext context,
  AudioImportState state,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return PipelineProgressSheet(state: state);
    },
  );
}

class PipelineProgressSheet extends StatelessWidget {
  const PipelineProgressSheet({required this.state, super.key});

  final AudioImportState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pipeline progress', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(state.progressLabel, style: context.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AudioImportPipelineStage.values.length,
                separatorBuilder: (context, index) =>
                    Divider(color: context.colors.outlineVariant),
                itemBuilder: (context, index) {
                  final stage = AudioImportPipelineStage.values[index];
                  return PipelineStepTile(
                    number: index + 1,
                    title: state.titleForStage(stage),
                    description: state.detailForStage(stage),
                    status: _statusFor(stage),
                    elapsedTime: _elapsedTimeFor(stage),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PipelineStepStatus _statusFor(AudioImportPipelineStage stage) {
    if (state.isStageFailed(stage)) {
      return PipelineStepStatus.failed;
    }
    if (state.isCancelled && state.activeStage == stage) {
      return PipelineStepStatus.cancelled;
    }
    if (state.isStageRunning(stage)) {
      return PipelineStepStatus.running;
    }
    if (state.isStageComplete(stage)) {
      return PipelineStepStatus.done;
    }
    return PipelineStepStatus.waiting;
  }

  String? _elapsedTimeFor(AudioImportPipelineStage stage) {
    if (!state.isStageComplete(stage)) {
      return null;
    }
    final index = AudioImportPipelineStage.values.indexOf(stage) + 1;
    return '${index * 2}s';
  }
}
