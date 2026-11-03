import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/caption_settings_fields.dart';
import 'package:picturestovideos/features/editor/widgets/clip_scope_selector.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipCaptionSettingsCard extends StatelessWidget {
  const ClipCaptionSettingsCard({
    super.key,
    required this.template,
    required this.duration,
    required this.caption,
    required this.supportingLine,
    required this.settings,
    required this.section,
    required this.previewFraction,
    required this.applyToAll,
    required this.onCaptionChanged,
    required this.onSettingsChanged,
    required this.onSectionChanged,
    required this.onPreviewFractionChanged,
    required this.onScopeChanged,
    this.enabled = true,
    this.supportsBackdrop = true,
    this.unavailableMessage,
  });

  final VideoTemplate template;
  final double duration;
  final TextEditingController caption;
  final TextEditingController supportingLine;
  final CaptionSettings settings;
  final CaptionEditorSection section;
  final double previewFraction;
  final bool applyToAll;
  final VoidCallback onCaptionChanged;
  final ValueChanged<CaptionSettings> onSettingsChanged;
  final ValueChanged<CaptionEditorSection> onSectionChanged;
  final ValueChanged<double> onPreviewFractionChanged;
  final ValueChanged<bool> onScopeChanged;
  final bool enabled;
  final bool supportsBackdrop;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) {
    final clipDuration = Duration(milliseconds: (duration * 1000).round());
    final ratio = template.aspectRatio;
    final layout = CaptionLayout(
      title: caption.text,
      supportingLine: supportingLine.text,
      template: template,
      settings: settings,
      width: ratio.exportWidth,
      height: ratio.exportHeight,
    );
    final visibleDuration = Duration(
      microseconds:
          (clipDuration.inMicroseconds *
                  (settings.endFraction - settings.startFraction))
              .round(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.captionTiming,
                    style: context.textTheme.labelLarge,
                  ),
                ),
                Text(
                  '${(clipDuration.inMilliseconds * previewFraction / 1000).toStringAsFixed(1)} s (${(previewFraction * 100).round()}%)',
                ),
              ],
            ),
            Slider(
              min: 0,
              max: 1,
              divisions: 100,
              value: previewFraction,
              semanticFormatterCallback: (value) =>
                  '${(clipDuration.inSeconds * value).toStringAsFixed(1)} s',
              onChanged: onPreviewFractionChanged,
            ),
            CaptionSettingsFields(
              settings: settings,
              section: section,
              onSectionChanged: onSectionChanged,
              overflow: layout.overflow,
              shortReadingTime: layout.readingTimeIsShort(visibleDuration),
              clipDuration: clipDuration,
              inheritedPlacement: const CaptionSettings().placementFor(
                template,
              ),
              enabled: enabled,
              supportsBackdrop: supportsBackdrop,
              onChanged: onSettingsChanged,
            ),
            if (section == CaptionEditorSection.text) ...[
              const SizedBox(height: 8),
              TextField(
                controller: caption,
                enabled: enabled,
                maxLength: 100,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.editorOptionalCaption,
                  suffixIcon: IconButton(
                    onPressed: enabled
                        ? () {
                            caption.clear();
                            onCaptionChanged();
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onChanged: (_) => onCaptionChanged(),
              ),
              TextField(
                controller: supportingLine,
                enabled: enabled,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: context.l10n.captionSupportingLine,
                ),
                onChanged: (_) => onCaptionChanged(),
              ),
            ],
            const SizedBox(height: 8),
            Text(switch (section) {
              CaptionEditorSection.text => context.l10n.captionSectionText,
              CaptionEditorSection.style => context.l10n.captionSectionStyle,
              CaptionEditorSection.position =>
                context.l10n.captionSectionPosition,
              CaptionEditorSection.timing => context.l10n.captionSectionTiming,
            }, style: context.textTheme.labelLarge),
            if (unavailableMessage != null)
              Text(unavailableMessage!, style: context.textTheme.bodySmall),
            ClipScopeSelector(
              all: applyToAll,
              onChanged: onScopeChanged,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }
}
