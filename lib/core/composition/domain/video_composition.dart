import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/composition/domain/frame_time_quantizer.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

/// Immutable, marker-independent input shared by the editor and renderers.
class VideoComposition {
  VideoComposition({
    required List<CompositionClip> clips,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.template,
    required this.audioMix,
    this.audioSourcePath,
    this.audioSourceDuration,
  }) : clips = List.unmodifiable(clips);

  final List<CompositionClip> clips;
  final int width;
  final int height;
  final int frameRate;
  final VideoTemplate template;
  final AudioMix audioMix;
  final String? audioSourcePath;
  final Duration? audioSourceDuration;

  Duration get duration => clips.isEmpty ? Duration.zero : clips.last.end;

  /// Normalizes all video timing onto this composition's output frame grid.
  /// Audio ranges retain sample-level timing.
  VideoComposition quantizedForOutput() {
    if (frameRate <= 0 || frameRate > 240) return this;
    final quantizer = FrameTimeQuantizer(frameRate);
    return VideoComposition(
      clips: [
        for (final clip in clips)
          clip.copyWith(
            start: quantizer.quantize(clip.start),
            end: quantizer.quantize(clip.end),
            transitionDuration: quantizer.quantize(clip.transitionDuration),
          ),
      ],
      width: width,
      height: height,
      frameRate: frameRate,
      template: template,
      audioMix: audioMix,
      audioSourcePath: audioSourcePath,
      audioSourceDuration: audioSourceDuration,
    );
  }

  /// Converts committed clip events once; marker events are never consulted.
  factory VideoComposition.fromProject({
    required ProjectTimeline project,
    required List<MediaTrackClipPayload> committedClips,
    required int width,
    required int height,
    required int frameRate,
    String? audioSourcePath,
  }) => VideoComposition(
    clips: List.unmodifiable([
      for (final clip in committedClips)
        CompositionClip.fromPayload(clip, project.template),
    ]),
    width: width,
    height: height,
    frameRate: frameRate,
    template: project.template,
    audioMix: project.audioMix,
    audioSourcePath: audioSourcePath ?? project.audioSourcePath,
    audioSourceDuration: project.audioDuration,
  );

  List<CompositionValidationFailure> validate() {
    final failures = <CompositionValidationFailure>[];
    if (clips.isEmpty) {
      failures.add(
        const CompositionValidationFailure(
          CompositionValidationCode.emptyComposition,
        ),
      );
    }
    if (width <= 0 || height <= 0) {
      failures.add(
        const CompositionValidationFailure(
          CompositionValidationCode.invalidOutputSize,
        ),
      );
    }
    if (frameRate <= 0 || frameRate > 240) {
      failures.add(
        const CompositionValidationFailure(
          CompositionValidationCode.invalidFrameRate,
        ),
      );
    }
    if (audioSourceDuration != null && audioSourceDuration! < Duration.zero) {
      failures.add(
        const CompositionValidationFailure(
          CompositionValidationCode.invalidAudioRange,
        ),
      );
    }
    final seenIds = <String>{};
    CompositionClip? previous;
    for (final clip in clips) {
      if (clip.clipId.trim().isEmpty) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.emptyClipId,
            clipId: clip.clipId,
          ),
        );
      } else if (!seenIds.add(clip.clipId)) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.duplicateClipId,
            clipId: clip.clipId,
          ),
        );
      }
      if (clip.sourcePath.trim().isEmpty) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.emptySource,
            clipId: clip.clipId,
          ),
        );
      }
      if (clip.start < Duration.zero || clip.end <= clip.start) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.invalidClipSpan,
            clipId: clip.clipId,
          ),
        );
      }
      if (clip.cropTransform.focalX < -1 ||
          clip.cropTransform.focalX > 1 ||
          clip.cropTransform.focalY < -1 ||
          clip.cropTransform.focalY > 1 ||
          clip.cropTransform.zoom < 1 ||
          clip.cropTransform.zoom > ImageCropTransform.maxZoom) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.invalidCrop,
            clipId: clip.clipId,
          ),
        );
      }
      if (clip.transitionDuration < Duration.zero ||
          clip.transitionDuration > const Duration(seconds: 5)) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.invalidTransition,
            clipId: clip.clipId,
          ),
        );
      }
      final caption = clip.captionSettings;
      if (caption.startFraction < 0 ||
          caption.endFraction > 1 ||
          caption.startFraction >= caption.endFraction) {
        failures.add(
          CompositionValidationFailure(
            CompositionValidationCode.invalidCaptionRange,
            clipId: clip.clipId,
          ),
        );
      }
      if (previous != null) {
        if (clip.start < previous.start) {
          failures.add(
            CompositionValidationFailure(
              CompositionValidationCode.clipsOutOfOrder,
              clipId: clip.clipId,
            ),
          );
        } else if (clip.start < previous.end) {
          failures.add(
            CompositionValidationFailure(
              CompositionValidationCode.overlappingClips,
              clipId: clip.clipId,
            ),
          );
        }
      }
      previous = clip;
    }
    if (audioMix.start < Duration.zero ||
        audioMix.fadeIn < Duration.zero ||
        audioMix.fadeOut < Duration.zero ||
        (audioMix.end != null && audioMix.end! <= audioMix.start)) {
      failures.add(
        const CompositionValidationFailure(
          CompositionValidationCode.invalidAudioRange,
        ),
      );
    }
    return List.unmodifiable(failures);
  }
}

class CompositionClip {
  const CompositionClip({
    required this.clipId,
    required this.mediaId,
    required this.title,
    required this.tagline,
    required this.sourcePath,
    required this.start,
    required this.end,
    required this.imageFit,
    required this.cropTransform,
    required this.motion,
    required this.caption,
    required this.captionSupportingLine,
    required this.captionSettings,
    required this.transitionType,
    required this.transitionDuration,
  });

  final String clipId;
  final String mediaId;
  final String title;
  final String tagline;
  final String sourcePath;
  final Duration start;
  final Duration end;
  final VideoTemplateImageFit imageFit;
  final ImageCropTransform cropTransform;
  final ClipMotion motion;
  final String caption;
  final String captionSupportingLine;
  final CaptionSettings captionSettings;
  final ClipTransitionType transitionType;
  final Duration transitionDuration;

  CompositionClip copyWith({
    Duration? start,
    Duration? end,
    Duration? transitionDuration,
  }) => CompositionClip(
    clipId: clipId,
    mediaId: mediaId,
    title: title,
    tagline: tagline,
    sourcePath: sourcePath,
    start: start ?? this.start,
    end: end ?? this.end,
    imageFit: imageFit,
    cropTransform: cropTransform,
    motion: motion,
    caption: caption,
    captionSupportingLine: captionSupportingLine,
    captionSettings: captionSettings,
    transitionType: transitionType,
    transitionDuration: transitionDuration ?? this.transitionDuration,
  );

  factory CompositionClip.fromPayload(
    MediaTrackClipPayload payload,
    VideoTemplate template,
  ) => CompositionClip(
    clipId: payload.clipId,
    mediaId: payload.mediaId,
    title: payload.title,
    tagline: payload.tagline,
    sourcePath: payload.sourcePath,
    start: payload.start,
    end: payload.end,
    imageFit: payload.imageFit,
    cropTransform: payload.cropTransform,
    motion: payload.motionFor(template),
    caption: payload.caption,
    captionSupportingLine: payload.captionSupportingLine,
    captionSettings: payload.captionSettings,
    transitionType:
        payload.transitionOverride ??
        ClipTransitionType.fromTemplate(template.transition),
    transitionDuration: payload.transitionDuration,
  );

  MediaTrackClipPayload toPayload() => MediaTrackClipPayload(
    clipId: clipId,
    mediaId: mediaId,
    title: title,
    tagline: tagline,
    start: start,
    end: end,
    sourcePath: sourcePath,
    imageFit: imageFit,
    cropTransform: cropTransform,
    caption: caption,
    captionSupportingLine: captionSupportingLine,
    captionSettings: captionSettings,
    motionOverride: motion.preset,
    motionIntensity: motion.intensity,
    useStyleMotionIntensity: false,
    transitionOverride: transitionType,
    transitionDuration: transitionDuration,
  );
}

enum CompositionValidationCode {
  emptyComposition,
  invalidOutputSize,
  invalidFrameRate,
  emptyClipId,
  duplicateClipId,
  emptySource,
  invalidClipSpan,
  clipsOutOfOrder,
  overlappingClips,
  invalidAudioRange,
  invalidCrop,
  invalidTransition,
  invalidCaptionRange,
}

class CompositionValidationFailure {
  const CompositionValidationFailure(this.code, {this.clipId});
  final CompositionValidationCode code;
  final String? clipId;
}

class CompositionValidationException implements Exception {
  const CompositionValidationException(this.failures);
  final List<CompositionValidationFailure> failures;

  @override
  String toString() =>
      'Invalid video composition: ${failures.map((failure) => failure.code.name).join(', ')}';
}
