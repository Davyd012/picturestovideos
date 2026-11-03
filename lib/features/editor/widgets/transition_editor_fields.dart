import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class TransitionEditorFields extends StatelessWidget {
  const TransitionEditorFields({
    required this.type,
    required this.duration,
    required this.isClamped,
    required this.onTypeChanged,
    required this.onDurationChanged,
    this.enabled = true,
    this.inheritedType,
    super.key,
  });
  final ClipTransitionType? type;
  final Duration duration;
  final bool isClamped;
  final ValueChanged<ClipTransitionType?> onTypeChanged;
  final ValueChanged<Duration> onDurationChanged;
  final bool enabled;
  final ClipTransitionType? inheritedType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ClipTransitionType?>(
          initialValue: type,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.transitionToNext),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                inheritedType == null
                    ? context.l10n.styleDefault
                    : '${context.l10n.styleDefault}: ${_typeLabel(context, inheritedType!)}',
              ),
            ),
            DropdownMenuItem(
              value: ClipTransitionType.cut,
              child: Text(context.l10n.transitionCut),
            ),
            DropdownMenuItem(
              value: ClipTransitionType.dissolve,
              child: Text(context.l10n.transitionDissolve),
            ),
            DropdownMenuItem(
              value: ClipTransitionType.slide,
              child: Text(context.l10n.transitionSlide),
            ),
            DropdownMenuItem(
              value: ClipTransitionType.zoom,
              child: Text(context.l10n.transitionZoom),
            ),
          ],
          onChanged: enabled ? onTypeChanged : null,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.transitionDuration,
                style: context.textTheme.labelLarge,
              ),
            ),
            Text('${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s'),
          ],
        ),
        Slider(
          value: duration.inMilliseconds.clamp(100, 2000).toDouble(),
          min: 100,
          max: 2000,
          divisions: 19,
          label: '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s',
          onChanged: enabled
              ? (value) =>
                    onDurationChanged(Duration(milliseconds: value.round()))
              : null,
        ),
        if (isClamped)
          Text(
            context.l10n.transitionClamped,
            style: context.textTheme.bodyMedium,
          ),
      ],
    );
  }

  String _typeLabel(BuildContext context, ClipTransitionType type) =>
      switch (type) {
        ClipTransitionType.cut => context.l10n.transitionCut,
        ClipTransitionType.dissolve => context.l10n.transitionDissolve,
        ClipTransitionType.slide => context.l10n.transitionSlide,
        ClipTransitionType.zoom => context.l10n.transitionZoom,
      };
}
