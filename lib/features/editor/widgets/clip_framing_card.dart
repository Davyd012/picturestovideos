import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_fields.dart';
import 'package:picturestovideos/features/editor/widgets/clip_scope_selector.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipFramingCard extends StatelessWidget {
  const ClipFramingCard({
    required this.fit,
    required this.crop,
    required this.ratio,
    required this.sourcePath,
    required this.showRatio,
    required this.all,
    required this.onFitChanged,
    required this.onCropChanged,
    required this.onRatioChanged,
    required this.onScopeChanged,
    super.key,
  });
  final VideoTemplateImageFit fit;
  final ImageCropTransform crop;
  final VideoTemplateAspectRatio ratio;
  final String sourcePath;
  final bool showRatio;
  final bool all;
  final ValueChanged<VideoTemplateImageFit> onFitChanged;
  final ValueChanged<ImageCropTransform> onCropChanged;
  final ValueChanged<VideoTemplateAspectRatio> onRatioChanged;
  final ValueChanged<bool> onScopeChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRatio) ...[
            Text(context.l10n.editorOutputRatio),
            Text(
              '${ratio.exportWidth} × ${ratio.exportHeight}',
              style: context.textTheme.bodySmall,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final value in [
                    VideoTemplateAspectRatio.landscape,
                    VideoTemplateAspectRatio.square,
                    VideoTemplateAspectRatio.portrait,
                  ]) ...[
                    ChoiceChip(
                      label: Text(value.label),
                      selected: ratio == value,
                      onSelected: (_) => onRatioChanged(value),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(context.l10n.adjustCrop),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(context.l10n.editorFit),
                  selected: fit == VideoTemplateImageFit.contain,
                  onSelected: (_) =>
                      onFitChanged(VideoTemplateImageFit.contain),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.l10n.editorFill),
                  selected: fit == VideoTemplateImageFit.cover,
                  onSelected: (_) => onFitChanged(VideoTemplateImageFit.cover),
                ),
              ],
            ),
          ),
          ClipFramingFields(
            imageFit: fit,
            crop: crop,
            sourcePath: sourcePath,
            aspectRatio: ratio.value,
            showPreview: false,
            showFitSelector: false,
            onFitChanged: onFitChanged,
            onCropChanged: onCropChanged,
          ),
          ClipScopeSelector(all: all, onChanged: onScopeChanged),
        ],
      ),
    ),
  );
}
