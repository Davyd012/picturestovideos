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

  test(
    'legacy caption JSON keeps its appearance when style keys are absent',
    () {
      final legacy = CaptionSettings.fromJson({
        'placement': 'top',
        'entrance': 'fade',
        'startFraction': 0.2,
        'endFraction': 0.8,
      });
      expect(legacy.placement, CaptionPlacement.top);
      expect(legacy.entrance, CaptionEntrance.fade);
      expect(legacy.startFraction, 0.2);
      expect(legacy.endFraction, 0.8);
      expect(legacy.sizeScale, 1);
      expect(legacy.textColor, CaptionTextColor.white);
      expect(legacy.backdrop, CaptionBackdrop.legacy);
    },
  );

  test(
    'style round trips and applying style preserves per-occurrence timing',
    () {
      const style = CaptionSettings(
        preset: CaptionStylePreset.bold,
        sizeScale: 1.2,
        textColor: CaptionTextColor.black,
        backdrop: CaptionBackdrop.strongPanel,
      );
      const occurrence = CaptionSettings(
        placement: CaptionPlacement.top,
        entrance: CaptionEntrance.slide,
        startFraction: 0.25,
        endFraction: 0.75,
      );
      final restored = CaptionSettings.fromJson(style.toJson());
      expect(restored.preset, CaptionStylePreset.bold);
      expect(restored.sizeScale, 1.2);
      expect(restored.textColor, CaptionTextColor.black);
      expect(restored.backdrop, CaptionBackdrop.strongPanel);

      final applied = occurrence.copyStyleFrom(restored);
      expect(applied.placement, CaptionPlacement.top);
      expect(applied.entrance, CaptionEntrance.slide);
      expect(applied.startFraction, 0.25);
      expect(applied.endFraction, 0.75);
      expect(applied.backdrop, CaptionBackdrop.strongPanel);
    },
  );

  test('unknown and invalid caption style values fall back safely', () {
    final invalid = CaptionSettings.fromJson({
      'placement': 'middle-ish',
      'entrance': 'bounce',
      'startFraction': 0.9,
      'endFraction': 0.2,
      'preset': 'neon',
      'sizeScale': 99,
      'textColor': 'yellow',
      'backdrop': 'gradient',
    });
    expect(invalid.placement, isNull);
    expect(invalid.entrance, CaptionEntrance.none);
    expect(invalid.startFraction, 0);
    expect(invalid.endFraction, 1);
    expect(invalid.preset, isNull);
    expect(invalid.sizeScale, 1.4);
    expect(invalid.textColor, CaptionTextColor.white);
    expect(invalid.backdrop, CaptionBackdrop.legacy);
  });

  test(
    'caption size scales with video coordinates and reports safe area overflow',
    () {
      final standard = CaptionLayout(
        title: 'A readable title',
        supportingLine: 'A short line',
        template: VideoTemplates.calmMemories,
        settings: const CaptionSettings(),
        width: 1080,
        height: 1920,
      );
      final large = CaptionLayout(
        title: 'A readable title',
        supportingLine: 'A short line',
        template: VideoTemplates.calmMemories,
        settings: const CaptionSettings(sizeScale: 1.4),
        width: 1080,
        height: 1920,
      );
      expect(large.titleSize, greaterThan(standard.titleSize));
      expect(large.top, greaterThanOrEqualTo(192));
      expect(large.top + large.totalHeight, lessThanOrEqualTo(1728));
    },
  );

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
