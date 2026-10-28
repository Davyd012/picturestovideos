import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';

void main() {
  testWidgets('canvas renders captions from the evaluator layer', (
    tester,
  ) async {
    final clip = CompositionClip(
      clipId: 'occurrence',
      mediaId: 'photo',
      title: 'Photo',
      tagline: '',
      sourcePath: '',
      start: Duration.zero,
      end: const Duration(seconds: 2),
      imageFit: VideoTemplateImageFit.cover,
      cropTransform: ImageCropTransform.centered,
      motion: const ClipMotion(
        preset: ClipMotionPreset.none,
        intensity: ClipMotionIntensity.subtle,
      ),
      caption: 'Shared caption',
      captionSupportingLine: '',
      captionSettings: const CaptionSettings(),
      transitionType: ClipTransitionType.cut,
      transitionDuration: Duration.zero,
    );
    final composition = VideoComposition(
      clips: [clip],
      width: 1280,
      height: 720,
      frameRate: 30,
      template: VideoTemplates.cleanMemories,
      audioMix: const AudioMix(),
    );
    const evaluator = CompositionEvaluator();
    final evaluated = evaluator.evaluate(composition, Duration.zero);
    final payload = evaluated.layers.single.clip.toPayload();
    final frame = EditorPreviewFrame(
      currentTime: evaluated.time,
      activeIndex: 0,
      progress: evaluated.layers.single.progress,
      clips: [payload],
      activeClip: payload,
      compositionFrame: evaluated,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 640,
            child: AspectRatio(
              aspectRatio: VideoTemplates.cleanMemories.aspectRatio.value,
              child: CompositionPreviewCanvas(
                frame: frame,
                template: VideoTemplates.cleanMemories,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Shared caption'), findsOneWidget);
  });
}
