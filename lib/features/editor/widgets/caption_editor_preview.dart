import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/preview/domain/caption_render_colors.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class CaptionEditorPreview extends StatelessWidget {
  const CaptionEditorPreview({
    required this.sourcePath,
    required this.title,
    required this.supportingLine,
    required this.settings,
    required this.template,
    required this.clipDuration,
    required this.previewTime,
    required this.width,
    super.key,
  });

  final String sourcePath;
  final String title;
  final String supportingLine;
  final CaptionSettings settings;
  final VideoTemplate template;
  final Duration clipDuration;
  final Duration previewTime;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ratio = template.aspectRatio;
    final layout = CaptionLayout(
      title: title,
      supportingLine: supportingLine,
      template: template,
      settings: settings,
      width: ratio.exportWidth,
      height: ratio.exportHeight,
    );
    final frame = settings.evaluate(previewTime, clipDuration);
    final scale = width / layout.width;
    final padding = (layout.titleSize / 2) * scale;
    final hasPanel =
        settings.backdrop == CaptionBackdrop.panel ||
        settings.backdrop == CaptionBackdrop.strongPanel;
    final slide = settings.entrance == CaptionEntrance.slide
        ? (layout.height / 30) * (1 - frame.entranceProgress) * scale
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: width,
          height: width / ratio.value,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (sourcePath.isNotEmpty)
                  Image.file(
                    File(sourcePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _PreviewPlaceholder(),
                  )
                else
                  _PreviewPlaceholder(),
                if (frame.visible)
                  Positioned(
                    top: layout.top * scale + slide - (hasPanel ? padding : 0),
                    left: width * 0.1,
                    right: width * 0.1,
                    child: Opacity(
                      opacity: frame.opacity,
                      child: hasPanel
                          ? ColoredBox(
                              color: CaptionRenderColors.backdrop(settings),
                              child: Padding(
                                padding: EdgeInsets.all(padding),
                                child: _CaptionText(
                                  layout: layout,
                                  scale: scale,
                                  settings: settings,
                                ),
                              ),
                            )
                          : _CaptionText(
                              layout: layout,
                              scale: scale,
                              settings: settings,
                            ),
                    ),
                  ),
                if (!frame.visible)
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(context.l10n.captionNotVisibleAtTime),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (layout.overflow)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.captionOverflowWarning,
              style: context.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _CaptionText extends StatelessWidget {
  const _CaptionText({
    required this.layout,
    required this.scale,
    required this.settings,
  });

  final CaptionLayout layout;
  final double scale;
  final CaptionSettings settings;

  @override
  Widget build(BuildContext context) {
    final color = CaptionRenderColors.text(settings);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (layout.titleText.isNotEmpty)
          _Line(
            text: layout.titleText,
            size: layout.titleSize * scale,
            color: color,
            title: true,
            legacyBackdrop: settings.backdrop == CaptionBackdrop.legacy,
          ),
        if (layout.gap > 0) SizedBox(height: layout.gap * scale),
        if (layout.supportText.isNotEmpty)
          _Line(
            text: layout.supportText,
            size: layout.supportSize * scale,
            color: color,
            title: false,
            legacyBackdrop: settings.backdrop == CaptionBackdrop.legacy,
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    required this.size,
    required this.color,
    required this.title,
    required this.legacyBackdrop,
  });

  final String text;
  final double size;
  final Color color;
  final bool title;
  final bool legacyBackdrop;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style:
          (title ? context.textTheme.titleMedium : context.textTheme.bodyMedium)
              ?.copyWith(fontSize: size, color: color),
    );
    if (!legacyBackdrop) return textWidget;
    return ColoredBox(
      color: CaptionRenderColors.backdrop(const CaptionSettings()),
      child: textWidget,
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHighest,
    child: Center(
      child: Icon(Icons.image_outlined, color: context.colors.onSurfaceVariant),
    ),
  );
}
