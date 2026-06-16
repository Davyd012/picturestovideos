import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';

void main() {
  group('VideoTemplate', () {
    test('serializes and deserializes a preset', () {
      final json = VideoTemplates.cinematicDark.toJson();
      final template = VideoTemplate.fromJson(json);

      expect(template.id, VideoTemplates.cinematicDark.id);
      expect(template.aspectRatio, VideoTemplateAspectRatio.portrait);
      expect(template.imageAnimation, VideoTemplateImageAnimation.slowZoomOut);
      expect(template.transition, VideoTemplateTransition.crossfade);
    });

    test('parses popular aspect ratio labels', () {
      expect(
        VideoTemplateAspectRatio.fromJson('16/9'),
        VideoTemplateAspectRatio.landscape,
      );
      expect(
        VideoTemplateAspectRatio.fromJson('4:3'),
        VideoTemplateAspectRatio.classic,
      );
      expect(
        VideoTemplateAspectRatio.fromJson('1:1'),
        VideoTemplateAspectRatio.square,
      );
      expect(
        VideoTemplateAspectRatio.fromJson('4/5'),
        VideoTemplateAspectRatio.socialPortrait,
      );
    });

    test('catalog falls back to clean memories for unknown ids', () {
      expect(VideoTemplates.byId('unknown'), VideoTemplates.cleanMemories);
    });
  });
}
