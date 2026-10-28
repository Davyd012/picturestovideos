import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';

void main() {
  test(
    'parses the listed filters, encoders, and muxers from FFmpeg output',
    () {
      const output = '''
Filters:
 T.. = Timeline support
 ... scale V->V Resize the input
 ... drawtext V->V Draw text
Encoders:
 V....D libx264 H.264
 A..... aac AAC
Muxers:
 E mp4 MP4 format
''';

      expect(
        parseFfmpegCapabilityList(
          output,
          kind: FfmpegCapabilityListKind.filters,
        ),
        containsAll(['scale', 'drawtext']),
      );
      expect(
        parseFfmpegCapabilityList(
          output,
          kind: FfmpegCapabilityListKind.encoders,
        ),
        containsAll(['libx264', 'aac']),
      );
      expect(
        parseFfmpegCapabilityList(
          output,
          kind: FfmpegCapabilityListKind.muxers,
        ),
        {'mp4'},
      );
    },
  );

  test('requires only capabilities used by the committed composition', () {
    final basic = _composition();
    final available = RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: {'scale', 'pad', 'crop'},
      encoders: {'libx264'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
    );
    expect(available.issuesFor(basic), isEmpty);

    final captioned = _composition(caption: 'Привет');
    expect(available.issuesFor(captioned), [RenderCapabilityIssue.missingFont]);
  });

  test('reports unsupported and missing renderer capabilities distinctly', () {
    final composition = _composition();
    final unsupported = RenderCapabilities(
      platformSupported: false,
      ffmpegAvailable: false,
      filters: const {},
      encoders: const {},
      muxers: const {},
      videoEncoder: '',
    );
    expect(unsupported.issuesFor(composition), [
      RenderCapabilityIssue.unsupportedPlatform,
    ]);

    final missingEncoder = RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: {'scale', 'pad', 'crop'},
      encoders: const {},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
    );
    expect(missingEncoder.issuesFor(composition), [
      RenderCapabilityIssue.missingEncoder,
    ]);
    expect(
      () => missingEncoder.requireFor(composition),
      throwsA(isA<RenderCapabilityException>()),
    );
  });

  test('editor feature availability follows the active renderer probe', () {
    final capable = RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: {'scale', 'crop', 'zoompan', 'xfade', 'drawtext', 'drawbox'},
      encoders: {'libx264'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
      fontPath: 'font.ttf',
    );
    expect(capable.supportsMotion, isTrue);
    expect(capable.supportsTransitions, isTrue);
    expect(capable.supportsCaptions, isTrue);
    expect(
      capable.supportsTemplate(VideoTemplates.storybook, clipCount: 2),
      isTrue,
    );

    final missingFeatures = RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: const {},
      encoders: {'libx264'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
      fontPath: 'font.ttf',
    );
    expect(missingFeatures.supportsMotion, isFalse);
    expect(missingFeatures.supportsTransitions, isFalse);
    expect(missingFeatures.supportsCaptions, isFalse);
    expect(
      missingFeatures.supportsTemplate(VideoTemplates.storybook, clipCount: 2),
      isFalse,
    );

    final unsupportedPlatform = RenderCapabilities(
      platformSupported: false,
      ffmpegAvailable: true,
      filters: {'zoompan', 'xfade', 'drawtext'},
      encoders: {'libx264'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
      fontPath: 'font.ttf',
    );
    expect(unsupportedPlatform.supportsMotion, isFalse);
    expect(unsupportedPlatform.supportsTransitions, isFalse);
    expect(unsupportedPlatform.supportsCaptions, isFalse);
  });
}

VideoComposition _composition({String caption = ''}) => VideoComposition(
  clips: [
    CompositionClip(
      clipId: 'clip-1',
      mediaId: 'photo-1',
      title: 'Photo',
      tagline: '',
      sourcePath: 'photo.jpg',
      start: Duration.zero,
      end: const Duration(seconds: 2),
      imageFit: VideoTemplateImageFit.cover,
      cropTransform: ImageCropTransform.centered,
      motion: const ClipMotion(
        preset: ClipMotionPreset.none,
        intensity: ClipMotionIntensity.subtle,
      ),
      caption: caption,
      captionSupportingLine: '',
      captionSettings: const CaptionSettings(),
      transitionType: ClipTransitionType.cut,
      transitionDuration: Duration.zero,
    ),
  ],
  width: 1280,
  height: 720,
  frameRate: 30,
  template: VideoTemplates.cleanMemories,
  audioMix: const AudioMix(),
);
