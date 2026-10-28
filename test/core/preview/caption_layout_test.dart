import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

void main() {
  test('caption timing, entrances and placement survive serialization', () {
    const settings = CaptionSettings(
      placement: CaptionPlacement.top,
      entrance: CaptionEntrance.fade,
      startFraction: 0.25,
      endFraction: 0.75,
    );
    const clip = MediaTrackClipPayload(
      mediaId: 'photo',
      title: '',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 4),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
      captionSettings: settings,
    );
    final restored = MediaTrackClipPayload.fromJson(clip.toJson())
        .captionSettings;
    expect(restored.placement, CaptionPlacement.top);
    final timing = restored.timingFor(const Duration(seconds: 4));
    expect(timing.startMicroseconds, 1000000);
    expect(timing.endMicroseconds, 3000000);
    expect(timing.entranceMicroseconds, 400000);
    expect(
      restored
          .evaluate(
            const Duration(milliseconds: 500),
            const Duration(seconds: 4),
          )
          .visible,
      isFalse,
    );
    expect(
      restored
          .evaluate(
            const Duration(milliseconds: 1200),
            const Duration(seconds: 4),
          )
          .opacity,
      closeTo(0.5, 0.001),
    );
    expect(
      restored
          .evaluate(const Duration(seconds: 2), const Duration(seconds: 4))
          .opacity,
      1,
    );
    expect(
      restored
          .evaluate(const Duration(seconds: 3), const Duration(seconds: 4))
          .visible,
      isFalse,
    );
  });

  test('wraps Unicode without splitting emoji and reports overflow and reading time', () {
    const family = '👨‍👩‍👧‍👦';
    for (final ratio in VideoTemplateAspectRatio.values) {
      final layout = CaptionLayout(
        title: List.filled(80, family).join(),
        supportingLine: 'Norge — Привет, мир!',
        template: VideoTemplates.calmMemories,
        settings: const CaptionSettings(placement: CaptionPlacement.top),
        width: ratio.exportWidth,
        height: ratio.exportHeight,
      );
      expect(layout.overflow, isTrue);
      expect(layout.top, greaterThanOrEqualTo(ratio.exportHeight ~/ 10));
      expect(layout.top + layout.totalHeight, lessThan(ratio.exportHeight));
      expect(
        layout.titleText
            .replaceAll(family, '')
            .replaceAll('\n', '')
            .replaceAll('…', ''),
        isEmpty,
      );
      expect(
        layout.readingTimeIsShort(const Duration(milliseconds: 100)),
        isTrue,
      );
    }
  });
}
