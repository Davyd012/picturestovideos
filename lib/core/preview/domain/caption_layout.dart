import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';

/// Video composition metrics. Both the preview and FFmpeg consume this layout.
class CaptionLayout {
  CaptionLayout({
    required String title,
    required String supportingLine,
    required VideoTemplate template,
    required CaptionSettings settings,
    required int width,
    required int height,
  }) : originalText = '$title $supportingLine',
       titleSize = math.max(
         1,
         (math.min(width, height) * (template.id == 'storybook' ? 0.06 : 0.05))
             .round(),
       ),
       supportSize = math.max(1, (math.min(width, height) * 0.035).round()),
       placement = settings.placementFor(template),
       width = width,
       height = height {
    final available = width * 0.8;
    final titleWrapped = _wrap(
      title,
      math.max(1, (available / (titleSize * 1.3)).floor()),
      3,
    );
    final supportWrapped = _wrap(
      supportingLine,
      math.max(1, (available / (supportSize * 1.3)).floor()),
      2,
    );
    titleText = titleWrapped.text;
    supportText = supportWrapped.text;
    overflow = titleWrapped.overflow || supportWrapped.overflow;
    titleLines = titleText.isEmpty ? 0 : titleText.split('\n').length;
    supportLines = supportText.isEmpty ? 0 : supportText.split('\n').length;
  }

  final int width;
  final int height;
  final String originalText;
  final int titleSize;
  final int supportSize;
  final CaptionPlacement placement;
  late final String titleText;
  late final String supportText;
  late final int titleLines;
  late final int supportLines;
  late final bool overflow;

  int get titleLineSpacing => (titleSize * 0.2).round();
  int get supportLineSpacing => (supportSize * 0.2).round();
  int get titleHeight => titleLines == 0
      ? 0
      : titleLines * titleSize + (titleLines - 1) * titleLineSpacing;
  int get supportHeight => supportLines == 0
      ? 0
      : supportLines * supportSize + (supportLines - 1) * supportLineSpacing;
  int get gap =>
      titleLines > 0 && supportLines > 0 ? (height * 0.02).round() : 0;
  int get totalHeight => titleHeight + gap + supportHeight;
  int get top => switch (placement) {
    CaptionPlacement.top => (height * 0.1).round(),
    CaptionPlacement.center => (height - totalHeight) ~/ 2,
    CaptionPlacement.bottom => (height * 0.9).round() - totalHeight,
  };
  int get supportTop => top + titleHeight + gap;

  bool readingTimeIsShort(Duration visibleDuration) {
    final words = originalText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return words > 0 && visibleDuration.inMilliseconds < (500 + words * 350);
  }
}

class _WrappedCaption {
  const _WrappedCaption(this.text, this.overflow);
  final String text;
  final bool overflow;
}

_WrappedCaption _wrap(String value, int width, int maxLines) {
  if (value.isEmpty) return const _WrappedCaption('', false);
  final lines = <String>[];
  for (final paragraph in value.replaceAll('\r\n', '\n').split('\n')) {
    var remaining = paragraph.characters.toList();
    if (remaining.isEmpty) {
      lines.add('');
      continue;
    }
    while (remaining.length > width) {
      var split = width;
      for (var i = width - 1; i > 0; i--) {
        if (remaining[i] == ' ') {
          split = i;
          break;
        }
      }
      lines.add(remaining.take(split).join().trimRight());
      remaining = remaining.skip(split).toList();
      while (remaining.isNotEmpty && remaining.first == ' ') {
        remaining.removeAt(0);
      }
    }
    lines.add(remaining.join());
  }
  final overflow = lines.length > maxLines;
  final result = lines.take(maxLines).toList();
  if (overflow) {
    final chars = result.last.characters.toList();
    result[result.length - 1] =
        '${chars.take(math.max(0, width - 1)).join().trimRight()}…';
  }
  return _WrappedCaption(result.join('\n'), overflow);
}
