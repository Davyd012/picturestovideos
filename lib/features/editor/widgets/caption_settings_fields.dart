import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/caption_render_colors.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

enum CaptionEditorSection { text, style, position, timing }

class CaptionSettingsFields extends StatelessWidget {
  const CaptionSettingsFields({
    required this.settings,
    required this.onChanged,
    required this.overflow,
    required this.shortReadingTime,
    this.section = CaptionEditorSection.text,
    this.onSectionChanged,
    this.clipDuration = Duration.zero,
    this.supportsBackdrop = true,
    this.enabled = true,
    super.key,
  });
  final CaptionSettings settings;
  final ValueChanged<CaptionSettings> onChanged;
  final bool overflow;
  final bool shortReadingTime;
  final CaptionEditorSection section;
  final ValueChanged<CaptionEditorSection>? onSectionChanged;
  final Duration clipDuration;
  final bool supportsBackdrop;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<CaptionEditorSection>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: CaptionEditorSection.text,
            label: Text(context.l10n.captionSectionText),
          ),
          ButtonSegment(
            value: CaptionEditorSection.style,
            label: Text(context.l10n.captionSectionStyle),
          ),
          ButtonSegment(
            value: CaptionEditorSection.position,
            label: Text(context.l10n.captionSectionPosition),
          ),
          ButtonSegment(
            value: CaptionEditorSection.timing,
            label: Text(context.l10n.captionSectionTiming),
          ),
        ],
        selected: {section},
        onSelectionChanged: (selection) =>
            onSectionChanged?.call(selection.first),
      ),
      if (section == CaptionEditorSection.style) ...[
        Text(context.l10n.captionStyle, style: context.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<CaptionStylePreset>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: CaptionStylePreset.clean,
              label: Text(context.l10n.captionStyleClean),
            ),
            ButtonSegment(
              value: CaptionStylePreset.softBackdrop,
              label: Text(context.l10n.captionStyleSoft),
              enabled: supportsBackdrop,
            ),
            ButtonSegment(
              value: CaptionStylePreset.bold,
              label: Text(context.l10n.captionStyleBold),
              enabled: supportsBackdrop,
            ),
          ],
          selected: settings.preset == null ? {} : {settings.preset!},
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(settings.applyPreset(selection.first));
                  }
                }
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.captionSize,
                style: context.textTheme.labelLarge,
              ),
            ),
            Text(
              '${(settings.sizeScale * 100).round()}%',
              style: context.textTheme.bodyMedium,
            ),
            IconButton(
              tooltip: context.l10n.captionReset,
              onPressed: enabled
                  ? () => onChanged(
                      settings.copyStyleFrom(const CaptionSettings()),
                    )
                  : null,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        Semantics(
          label: context.l10n.captionSize,
          value: '${(settings.sizeScale * 100).round()}%',
          child: Slider(
            min: 0.7,
            max: 1.4,
            divisions: 14,
            value: settings.sizeScale,
            onChanged: enabled
                ? (value) => onChanged(
                    settings.copyWith(sizeScale: value, clearPreset: true),
                  )
                : null,
          ),
        ),
        DropdownButtonFormField<CaptionTextColor>(
          initialValue: settings.textColor,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.captionTextColor),
          items: [
            DropdownMenuItem(
              value: CaptionTextColor.white,
              child: _CaptionTextColorChoice(
                label: context.l10n.captionColorLight,
                color: CaptionRenderColors.text(
                  const CaptionSettings(textColor: CaptionTextColor.white),
                ),
              ),
            ),
            DropdownMenuItem(
              value: CaptionTextColor.black,
              child: _CaptionTextColorChoice(
                label: context.l10n.captionColorDark,
                color: CaptionRenderColors.text(
                  const CaptionSettings(textColor: CaptionTextColor.black),
                ),
              ),
            ),
          ],
          onChanged: enabled
              ? (value) => value == null
                    ? null
                    : onChanged(
                        settings.copyWith(textColor: value, clearPreset: true),
                      )
              : null,
        ),
        DropdownButtonFormField<CaptionBackdrop>(
          initialValue: settings.backdrop,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.captionBackdrop),
          items: [
            DropdownMenuItem(
              value: CaptionBackdrop.legacy,
              child: Text(context.l10n.captionBackdropClassic),
            ),
            DropdownMenuItem(
              value: CaptionBackdrop.none,
              child: Text(context.l10n.captionBackdropNone),
            ),
            DropdownMenuItem(
              value: CaptionBackdrop.panel,
              enabled: supportsBackdrop,
              child: Text(context.l10n.captionBackdropSoft),
            ),
            DropdownMenuItem(
              value: CaptionBackdrop.strongPanel,
              enabled: supportsBackdrop,
              child: Text(context.l10n.captionBackdropStrong),
            ),
          ],
          onChanged: enabled
              ? (value) => value == null
                    ? null
                    : onChanged(
                        settings.copyWith(backdrop: value, clearPreset: true),
                      )
              : null,
        ),
        if (settings.backdrop == CaptionBackdrop.none)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.captionNoBackdropWarning,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        if (settings.textColor == CaptionTextColor.black &&
            settings.backdrop != CaptionBackdrop.none)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.captionLowContrastWarning,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        if (!supportsBackdrop)
          Text(
            context.l10n.captionBackdropUnavailable,
            style: context.textTheme.bodySmall,
          ),
        Text(context.l10n.captionFont, style: context.textTheme.labelLarge),
        Text(
          context.l10n.captionFontUnavailable,
          style: context.textTheme.bodySmall,
        ),
      ],
      if (section == CaptionEditorSection.position)
        DropdownButtonFormField<CaptionPlacement?>(
          initialValue: settings.placement,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.captionPlacement),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(context.l10n.styleDefault),
            ),
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
              ? (value) => onChanged(settings.copyWith(placement: value))
              : null,
        ),
      if (section == CaptionEditorSection.timing) ...[
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
                    onChanged(settings.copyWith(entrance: value));
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
              _timeLabel(clipDuration, settings.startFraction),
              _timeLabel(clipDuration, settings.endFraction),
            ),
            onChanged: enabled
                ? (value) {
                    if (value.start < value.end) {
                      onChanged(
                        settings.copyWith(
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
          '${_timeLabel(clipDuration, settings.startFraction)} – ${_timeLabel(clipDuration, settings.endFraction)}',
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
    ],
  );

  String _timeLabel(Duration duration, double fraction) {
    if (duration <= Duration.zero) return '${(fraction * 100).round()}%';
    final totalTenths = (duration.inMilliseconds * fraction / 100).round();
    final seconds = totalTenths ~/ 10;
    final tenths = totalTenths % 10;
    return '$seconds.$tenths s';
  }
}

class _CaptionTextColorChoice extends StatelessWidget {
  const _CaptionTextColorChoice({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: const SizedBox.square(dimension: 24),
      ),
      const SizedBox(width: 8),
      Text(label),
    ],
  );
}
