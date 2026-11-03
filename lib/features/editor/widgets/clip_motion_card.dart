import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/clip_scope_selector.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipMotionCard extends StatelessWidget {
  const ClipMotionCard({
    required this.template,
    required this.motion,
    required this.intensity,
    required this.all,
    required this.onMotionChanged,
    required this.onIntensityChanged,
    required this.onScopeChanged,
    this.enabled = true,
    this.unavailableMessage,
    super.key,
  });
  final VideoTemplate template;
  final ClipMotionPreset? motion;
  final ClipMotionIntensity? intensity;
  final bool all;
  final ValueChanged<ClipMotionPreset?> onMotionChanged;
  final ValueChanged<ClipMotionIntensity?> onIntensityChanged;
  final ValueChanged<bool> onScopeChanged;
  final bool enabled;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.motion, style: context.textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in <(ClipMotionPreset?, String)>[
                (
                  null,
                  '${context.l10n.styleDefault}: ${_label(context, ClipMotionPreset.fromTemplate(template.imageAnimation))}',
                ),
                (ClipMotionPreset.none, context.l10n.motionNone),
                (ClipMotionPreset.slowZoomIn, context.l10n.motionZoomIn),
                (ClipMotionPreset.slowZoomOut, context.l10n.motionZoomOut),
                (ClipMotionPreset.gentlePan, context.l10n.motionPanForward),
                (
                  ClipMotionPreset.gentlePanReverse,
                  context.l10n.motionPanReverse,
                ),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: motion == entry.$1,
                  onSelected: enabled ? (_) => onMotionChanged(entry.$1) : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ClipMotionIntensity?>(
            initialValue: intensity,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n.motionIntensity,
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  '${context.l10n.styleDefault}: ${template.moreMovementByDefault ? context.l10n.motionMore : context.l10n.motionSubtle}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: ClipMotionIntensity.subtle,
                child: Text(context.l10n.motionSubtle),
              ),
              DropdownMenuItem(
                value: ClipMotionIntensity.moreMovement,
                child: Text(context.l10n.motionMore),
              ),
            ],
            onChanged: enabled ? onIntensityChanged : null,
          ),
          if (unavailableMessage != null)
            Text(unavailableMessage!, style: context.textTheme.bodySmall),
          ClipScopeSelector(
            all: all,
            onChanged: onScopeChanged,
            enabled: enabled,
          ),
        ],
      ),
    ),
  );

  String _label(BuildContext context, ClipMotionPreset preset) =>
      switch (preset) {
        ClipMotionPreset.none => context.l10n.motionNone,
        ClipMotionPreset.slowZoomIn => context.l10n.motionZoomIn,
        ClipMotionPreset.slowZoomOut => context.l10n.motionZoomOut,
        ClipMotionPreset.gentlePan => context.l10n.motionPanForward,
        ClipMotionPreset.gentlePanReverse => context.l10n.motionPanReverse,
      };
}
