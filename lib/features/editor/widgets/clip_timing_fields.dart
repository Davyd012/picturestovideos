import 'package:flutter/material.dart';
import 'package:picturestovideos/core/timeline/application/edit_clip_boundary_use_case.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class ClipTimingFields extends StatelessWidget {
  const ClipTimingFields({
    required this.initialDuration,
    required this.maxDuration,
    required this.snap,
    required this.onDurationChanged,
    required this.onSnapChanged,
    super.key,
  });
  final Duration initialDuration;
  final Duration maxDuration;
  final bool snap;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<bool> onSnapChanged;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = maxDuration.inMilliseconds / 1000;
    return Column(
      children: [
        TextFormField(
          initialValue: (initialDuration.inMilliseconds / 1000).toStringAsFixed(
            3,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.l10n.clipDuration),
          onChanged: onDurationChanged,
          validator: (value) {
            final seconds = double.tryParse((value ?? '').replaceAll(',', '.'));
            final original = initialDuration.inMilliseconds / 1000;
            if (seconds == original) return null;
            if (seconds == null ||
                !seconds.isFinite ||
                seconds <
                    EditClipBoundaryUseCase.minimumClipDuration.inMilliseconds /
                        1000 ||
                seconds > maxSeconds) {
              return context.l10n.durationRange(maxSeconds.toStringAsFixed(2));
            }
            return null;
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.snapToMarkers),
          subtitle: Text(context.l10n.snapDescription),
          value: snap,
          onChanged: onSnapChanged,
        ),
      ],
    );
  }
}
