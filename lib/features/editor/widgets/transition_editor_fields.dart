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
    super.key,
  });
  final ClipTransitionType? type;
  final Duration duration;
  final bool isClamped;
  final ValueChanged<ClipTransitionType?> onTypeChanged;
  final ValueChanged<Duration> onDurationChanged;
  final bool enabled;

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
              child: Text(context.l10n.styleDefault),
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
          ],
          onChanged: enabled ? onTypeChanged : null,
        ),
        Text(
          context.l10n.transitionDuration,
          style: context.textTheme.labelLarge,
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
}
