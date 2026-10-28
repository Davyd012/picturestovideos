import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipFramingFields extends StatelessWidget {
  const ClipFramingFields({
    required this.imageFit,
    required this.crop,
    required this.sourcePath,
    required this.aspectRatio,
    required this.onFitChanged,
    required this.onCropChanged,
    super.key,
  });

  final VideoTemplateImageFit imageFit;
  final ImageCropTransform crop;
  final String sourcePath;
  final double aspectRatio;
  final ValueChanged<VideoTemplateImageFit> onFitChanged;
  final ValueChanged<ImageCropTransform> onCropChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          image: true,
          label: context.l10n.framingPreview,
          child: ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRect(
                child: ColoredBox(
                  color: context.colors.scrim,
                  child: sourcePath.isEmpty
                      ? const SizedBox.expand()
                      : Transform.scale(
                          scale: imageFit == VideoTemplateImageFit.contain
                              ? 1
                              : crop.zoom,
                          alignment: Alignment(crop.focalX, crop.focalY),
                          child: Image.file(
                            File(sourcePath),
                            fit: imageFit == VideoTemplateImageFit.contain
                                ? BoxFit.contain
                                : BoxFit.cover,
                            alignment: Alignment(crop.focalX, crop.focalY),
                            errorBuilder: (context, error, stackTrace) =>
                                Center(child: Text(context.l10n.missingImage)),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: crop.isCentered
                ? null
                : () => onCropChanged(ImageCropTransform.centered),
            icon: const Icon(Icons.center_focus_strong),
            label: Text(context.l10n.centerImage),
          ),
        ),
        DropdownButtonFormField<VideoTemplateImageFit>(
          initialValue: imageFit,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.adjustCrop),
          items: [
            DropdownMenuItem(
              value: VideoTemplateImageFit.cover,
              child: Text(
                context.l10n.fillFrameCrop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: VideoTemplateImageFit.contain,
              child: Text(
                context.l10n.fullImage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) onFitChanged(value);
          },
        ),
        if (imageFit == VideoTemplateImageFit.contain)
          Text(
            context.l10n.cropOnlyForFill,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        _slider(
          context,
          context.l10n.cropZoom,
          crop.zoom,
          1,
          ImageCropTransform.maxZoom,
          (value) => crop.copyWith(zoom: value),
          valueFormatter: (value) =>
              context.l10n.cropZoomValue(value.toStringAsFixed(1)),
          enabled: imageFit == VideoTemplateImageFit.cover,
        ),
        _slider(
          context,
          context.l10n.cropHorizontal,
          crop.focalX,
          -1,
          1,
          (value) => crop.copyWith(focalX: value),
          valueFormatter: (value) => _positionValue(
            context,
            value,
            context.l10n.cropDirectionLeft,
            context.l10n.cropDirectionRight,
          ),
          enabled: imageFit == VideoTemplateImageFit.cover,
        ),
        _slider(
          context,
          context.l10n.cropVertical,
          crop.focalY,
          -1,
          1,
          (value) => crop.copyWith(focalY: value),
          valueFormatter: (value) => _positionValue(
            context,
            value,
            context.l10n.cropDirectionUp,
            context.l10n.cropDirectionDown,
          ),
          enabled: imageFit == VideoTemplateImageFit.cover,
        ),
      ],
    );
  }

  Widget _slider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ImageCropTransform Function(double) update, {
    required String Function(double) valueFormatter,
    required bool enabled,
  }) {
    final formattedValue = valueFormatter(value);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              ExcludeSemantics(
                child: Text(formattedValue, style: context.textTheme.bodySmall),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            semanticFormatterCallback: valueFormatter,
            onChanged: enabled ? (value) => onCropChanged(update(value)) : null,
          ),
        ],
      ),
    );
  }

  String _positionValue(
    BuildContext context,
    double value,
    String negativeDirection,
    String positiveDirection,
  ) {
    if (value == 0) return context.l10n.cropPositionCentered;
    final direction = value < 0 ? negativeDirection : positiveDirection;
    final percent = (value.abs() * 100).round().toString();
    return context.l10n.cropOffsetValue(direction, percent);
  }
}
