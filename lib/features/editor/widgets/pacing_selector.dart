import 'package:flutter/material.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/core/timeline/domain/pacing_suggestion_summary.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class PacingSelector extends StatelessWidget {
  const PacingSelector({
    required this.value,
    required this.hasManualEdits,
    required this.onChanged,
    required this.onApply,
    this.onUndo,
    required this.duration,
    this.suggestionSummary,
    super.key,
  });
  final SequencePacing value;
  final bool hasManualEdits;
  final ValueChanged<SequencePacing> onChanged;
  final Future<void> Function()? onApply;
  final VoidCallback? onUndo;
  final Duration? duration;
  final PacingSuggestionSummary? suggestionSummary;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.pacing, style: context.textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final option in SequencePacing.values)
                ChoiceChip(
                  label: Text(switch (option) {
                    SequencePacing.relaxed => context.l10n.pacingRelaxed,
                    SequencePacing.balanced => context.l10n.pacingBalanced,
                    SequencePacing.energetic => context.l10n.pacingEnergetic,
                  }),
                  selected: value == option,
                  onSelected: (_) => onChanged(option),
                ),
            ],
          ),
          Text(
            context.l10n.pacingExplanation,
            style: context.textTheme.bodyMedium,
          ),
          if (duration != null)
            Text(
              context.l10n.expectedVideoDuration(_formatDuration(duration!)),
              style: context.textTheme.bodyMedium,
            ),
          if (suggestionSummary case final summary?) ...[
            Text(
              context.l10n.pacingTimingImpact(
                changed: summary.changedCount,
                total: summary.clipCount,
                added: summary.addedCount,
                removed: summary.removedCount,
              ),
              style: context.textTheme.bodyMedium,
            ),
            if (summary.shortestClip case final shortest?)
              Text(
                context.l10n.pacingClipDurationRange(
                  _formatDuration(shortest),
                  _formatDuration(summary.longestClip ?? shortest),
                ),
                style: context.textTheme.bodyMedium,
              ),
          ],
          if (hasManualEdits)
            Text(
              context.l10n.pacingManualNotice,
              style: context.textTheme.bodyMedium,
            ),
          FilledButton.tonalIcon(
            onPressed: onApply == null ? null : () => _apply(context),
            icon: const Icon(Icons.auto_awesome),
            label: Text(context.l10n.applyPacing),
          ),
        ],
      ),
    ),
  );

  Future<void> _apply(BuildContext context) async {
    final apply = onApply;
    if (apply == null) return;
    if (hasManualEdits) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.pacingOverwriteTitle),
          content: Text(context.l10n.pacingOverwriteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirmPacing),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await apply();
    if (context.mounted && onUndo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pacingApplied),
          action: SnackBarAction(label: context.l10n.undo, onPressed: onUndo!),
        ),
      );
    }
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
