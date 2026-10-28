import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

void main() {
  test('motion endpoints and intensity are deterministic', () {
    const zoom = ClipMotion(
      preset: ClipMotionPreset.slowZoomIn,
      intensity: ClipMotionIntensity.moreMovement,
    );
    expect(zoom.zoomAt(0), 1);
    expect(zoom.zoomAt(0.5), closeTo(1.08, 0.000001));
    expect(zoom.zoomAt(1), closeTo(1.16, 0.000001));
    const out = ClipMotion(
      preset: ClipMotionPreset.slowZoomOut,
      intensity: ClipMotionIntensity.subtle,
    );
    expect(out.zoomAt(0), closeTo(1.08, 0.000001));
    expect(out.zoomAt(1), 1);
  });

  test(
    'style intensity defaults change without overwriting an explicit choice',
    () {
      const clip = MediaTrackClipPayload(
        mediaId: 'p',
        title: '',
        tagline: '',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      );
      expect(
        clip.motionFor(VideoTemplates.calmMemories).intensity,
        ClipMotionIntensity.subtle,
      );
      expect(
        clip.motionFor(VideoTemplates.celebration).intensity,
        ClipMotionIntensity.moreMovement,
      );
      final explicit = clip.copyWith(
        motionIntensity: ClipMotionIntensity.subtle,
      );
      expect(
        explicit.motionFor(VideoTemplates.celebration).intensity,
        ClipMotionIntensity.subtle,
      );
      expect(
        MediaTrackClipPayload.fromJson(explicit.toJson())
            .motionFor(VideoTemplates.celebration)
            .intensity,
        ClipMotionIntensity.subtle,
      );
    },
  );

  test('pan anchors stay in range and keep edge focal points fixed', () {
    const pan = ClipMotion(
      preset: ClipMotionPreset.gentlePan,
      intensity: ClipMotionIntensity.subtle,
    );
    expect(pan.horizontalAnchorAt(0, 0), 0);
    expect(pan.horizontalAnchorAt(1, 0), 1);
    for (final progress in [0.0, 0.5, 1.0]) {
      expect(pan.horizontalAnchorAt(progress, -1), 0);
      expect(pan.horizontalAnchorAt(progress, 1), 1);
    }
  });

  test(
    'motion overrides survive serialization and can return to style defaults',
    () {
      const clip = MediaTrackClipPayload(
        mediaId: 'p',
        title: '',
        tagline: '',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      );
      final edited = clip.copyWith(
        motionOverride: ClipMotionPreset.gentlePan,
        motionIntensity: ClipMotionIntensity.moreMovement,
      );
      final restored = MediaTrackClipPayload.fromJson(edited.toJson());
      expect(
        restored.motionFor(VideoTemplates.cleanMemories).preset,
        ClipMotionPreset.gentlePan,
      );
      expect(restored.motionIntensity, ClipMotionIntensity.moreMovement);
      expect(
        restored
            .copyWith(clearMotionOverride: true)
            .motionFor(VideoTemplates.cleanMemories)
            .preset,
        ClipMotionPreset.slowZoomIn,
      );
    },
  );
}
