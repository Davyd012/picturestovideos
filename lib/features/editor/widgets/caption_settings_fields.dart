import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class CaptionSettingsFields extends StatelessWidget {
  const CaptionSettingsFields({
    required this.settings,
    required this.onChanged,
    required this.overflow,
    required this.shortReadingTime,
    this.enabled = true,
    super.key,
  });
  final CaptionSettings settings;
  final ValueChanged<CaptionSettings> onChanged;
  final bool overflow;
  final bool shortReadingTime;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<CaptionPlacement?>(
        initialValue: settings.placement,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.captionPlacement),
        items: [
          DropdownMenuItem(value: null, child: Text(context.l10n.styleDefault)),
          DropdownMenuItem(
            value: CaptionPlacement.bottom,
            child: Text(context.l10n.captionBottom),
          ),
          DropdownMenuItem(
            value: CaptionPlacement.center,
            child: Text(context.l10n.captionCenter),
          ),
          DropdownMenuItem(
            value: CaptionPlacement.top,
            child: Text(context.l10n.captionTop),
          ),
        ],
        onChanged: enabled
            ? (value) => onChanged(
                CaptionSettings(
                  placement: value,
                  entrance: settings.entrance,
                  startFraction: settings.startFraction,
                  endFraction: settings.endFraction,
                ),
              )
            : null,
      ),
      DropdownButtonFormField<CaptionEntrance>(
        initialValue: settings.entrance,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.captionEntrance),
        items: [
          DropdownMenuItem(
            value: CaptionEntrance.none,
            child: Text(context.l10n.captionEntranceNone),
          ),
          DropdownMenuItem(
            value: CaptionEntrance.fade,
            child: Text(context.l10n.captionEntranceFade),
          ),
          DropdownMenuItem(
            value: CaptionEntrance.slide,
            child: Text(context.l10n.captionEntranceSlide),
          ),
        ],
        onChanged: enabled
            ? (value) {
                if (value != null) {
                  onChanged(
                    CaptionSettings(
                      placement: settings.placement,
                      entrance: value,
                      startFraction: settings.startFraction,
                      endFraction: settings.endFraction,
                    ),
                  );
                }
              }
            : null,
      ),
      Text(context.l10n.captionTiming, style: context.textTheme.labelLarge),
      Semantics(
        label: context.l10n.captionTiming,
        child: RangeSlider(
          values: RangeValues(settings.startFraction, settings.endFraction),
          min: 0,
          max: 1,
          divisions: 20,
          labels: RangeLabels(
            '${(settings.startFraction * 100).round()}%',
            '${(settings.endFraction * 100).round()}%',
          ),
          onChanged: enabled
              ? (value) {
                  if (value.start < value.end) {
                    onChanged(
                      CaptionSettings(
                        placement: settings.placement,
                        entrance: settings.entrance,
                        startFraction: value.start,
                        endFraction: value.end,
                      ),
                    );
                  }
                }
              : null,
        ),
      ),
      Text(
        '${(settings.startFraction * 100).round()}% – ${(settings.endFraction * 100).round()}%',
        style: context.textTheme.bodyMedium,
      ),
      if (overflow)
        Text(
          context.l10n.captionOverflowWarning,
          style: context.textTheme.bodyMedium,
        ),
      if (shortReadingTime)
        Text(
          context.l10n.captionReadingWarning,
          style: context.textTheme.bodyMedium,
        ),
    ],
  );
}
