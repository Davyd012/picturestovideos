import 'package:flutter/material.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

enum PipelineStepStatus { waiting, running, done, failed, cancelled }

class PipelineStepTile extends StatelessWidget {
  const PipelineStepTile({
    required this.number,
    required this.title,
    required this.description,
    required this.status,
    required this.elapsedTime,
    super.key,
  });

  final int number;
  final String title;
  final String description;
  final PipelineStepStatus status;
  final String? elapsedTime;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _StepLeading(number: number, status: status),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(description),
          if (elapsedTime != null) ...[
            const SizedBox(height: 4),
            Text(elapsedTime!, style: context.textTheme.labelMedium),
          ],
        ],
      ),
      trailing: _StatusBadge(status: status),
    );
  }
}

class _StepLeading extends StatelessWidget {
  const _StepLeading({required this.number, required this.status});

  final int number;
  final PipelineStepStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      PipelineStepStatus.done => Icons.check,
      PipelineStepStatus.failed => Icons.error_outline,
      PipelineStepStatus.cancelled => Icons.close,
      PipelineStepStatus.running => Icons.sync,
      PipelineStepStatus.waiting => null,
    };

    return CircleAvatar(
      backgroundColor: switch (status) {
        PipelineStepStatus.done ||
        PipelineStepStatus.running => context.colors.primaryContainer,
        PipelineStepStatus.failed => context.colors.errorContainer,
        PipelineStepStatus.cancelled ||
        PipelineStepStatus.waiting => context.colors.surfaceContainerHighest,
      },
      foregroundColor: switch (status) {
        PipelineStepStatus.failed => context.colors.onErrorContainer,
        PipelineStepStatus.done ||
        PipelineStepStatus.running => context.colors.onPrimaryContainer,
        PipelineStepStatus.cancelled ||
        PipelineStepStatus.waiting => context.colors.onSurface,
      },
      child: icon == null ? Text('$number') : Icon(icon),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PipelineStepStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label),
      backgroundColor: switch (status) {
        PipelineStepStatus.done ||
        PipelineStepStatus.running => context.colors.primaryContainer,
        PipelineStepStatus.failed => context.colors.errorContainer,
        PipelineStepStatus.cancelled ||
        PipelineStepStatus.waiting => context.colors.surfaceContainerHighest,
      },
    );
  }

  String get _label {
    return switch (status) {
      PipelineStepStatus.waiting => 'Waiting',
      PipelineStepStatus.running => 'Running',
      PipelineStepStatus.done => 'Done',
      PipelineStepStatus.failed => 'Failed',
      PipelineStepStatus.cancelled => 'Cancelled',
    };
  }
}
