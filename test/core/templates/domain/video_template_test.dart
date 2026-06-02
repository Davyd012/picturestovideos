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

    test('catalog falls back to clean memories for unknown ids', () {
      expect(VideoTemplates.byId('unknown'), VideoTemplates.cleanMemories);
    });
  });
}
