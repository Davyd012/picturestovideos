import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';

class MediaTrackClipPayload {
  const MediaTrackClipPayload({
    required this.mediaId,
    this.clipId = '',
    required this.title,
    required this.tagline,
    required this.start,
    required this.end,
    required this.sourcePath,
    required this.imageFit,
    this.cropTransform = ImageCropTransform.centered,
    this.caption = '',
    this.captionSupportingLine = '',
    this.captionSettings = const CaptionSettings(),
    this.motionOverride,
    this.motionIntensity = ClipMotionIntensity.subtle,
    this.useStyleMotionIntensity = true,
    this.transitionOverride,
    this.transitionDuration = const Duration(milliseconds: 600),
  });

  final String mediaId;
  final String clipId;
  final String title;
  final String tagline;
  final Duration start;
  final Duration end;
  final String sourcePath;
  final VideoTemplateImageFit imageFit;
  final ImageCropTransform cropTransform;
  final String caption;
  final String captionSupportingLine;
  final CaptionSettings captionSettings;
  final ClipMotionPreset? motionOverride;
  final ClipMotionIntensity motionIntensity;
  final bool useStyleMotionIntensity;
  final ClipTransitionType? transitionOverride;
  final Duration transitionDuration;

  ClipMotion motionFor(VideoTemplate template) => ClipMotion(
    preset:
        motionOverride ??
        ClipMotionPreset.fromTemplate(template.imageAnimation),
    intensity: useStyleMotionIntensity
        ? (template.moreMovementByDefault
              ? ClipMotionIntensity.moreMovement
              : ClipMotionIntensity.subtle)
        : motionIntensity,
  );

  Map<String, Object?> toJson() {
    return {
      'kind': 'media-track-clip',
      'mediaId': mediaId,
      'clipId': clipId,
      'title': title,
      'tagline': tagline,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
      'sourcePath': sourcePath,
      'imageFit': imageFit.name,
      'cropTransform': cropTransform.toJson(),
      'caption': caption,
      'captionSupportingLine': captionSupportingLine,
      'captionSettings': captionSettings.toJson(),
      'motionOverride': motionOverride?.name,
      'motionIntensity': motionIntensity.name,
      'useStyleMotionIntensity': useStyleMotionIntensity,
      'transitionOverride': transitionOverride?.name,
      'transitionDurationMs': transitionDuration.inMilliseconds,
    };
  }

  factory MediaTrackClipPayload.fromJson(
    Map<String, Object?> json, {
    String? legacyClipId,
  }) {
    return MediaTrackClipPayload(
      mediaId: json['mediaId']! as String,
      clipId: (json['clipId'] as String?)?.isNotEmpty == true
          ? json['clipId']! as String
          : legacyClipId ?? 'legacy-${json['mediaId']}-${json['startMs']}',
      title: json['title']! as String,
      tagline: json['tagline']! as String,
      start: Duration(milliseconds: json['startMs']! as int),
      end: Duration(milliseconds: json['endMs']! as int),
      sourcePath: json['sourcePath']! as String,
      imageFit: VideoTemplateImageFit.fromJson(json['imageFit'] as String?),
      cropTransform: ImageCropTransform.fromJson(json['cropTransform']),
      caption: json['caption'] as String? ?? json['title']! as String,
      captionSupportingLine:
          json['captionSupportingLine'] as String? ??
          json['tagline']! as String,
      captionSettings: CaptionSettings.fromJson(json['captionSettings']),
      motionOverride: ClipMotionPreset.values
          .where((value) => value.name == json['motionOverride'])
          .firstOrNull,
      motionIntensity:
          ClipMotionIntensity.values
              .where((value) => value.name == json['motionIntensity'])
              .firstOrNull ??
          ClipMotionIntensity.subtle,
      useStyleMotionIntensity:
          json['useStyleMotionIntensity'] as bool? ?? false,
      transitionOverride: ClipTransitionType.values
          .where((value) => value.name == json['transitionOverride'])
          .firstOrNull,
      transitionDuration: Duration(
        milliseconds: (json['transitionDurationMs'] as int? ?? 600).clamp(
          0,
          5000,
        ),
      ),
    );
  }

  MediaTrackClipPayload copyWith({
    String? mediaId,
    String? clipId,
    String? title,
    String? tagline,
    Duration? start,
    Duration? end,
    String? sourcePath,
    VideoTemplateImageFit? imageFit,
    ImageCropTransform? cropTransform,
    String? caption,
    String? captionSupportingLine,
    CaptionSettings? captionSettings,
    ClipMotionPreset? motionOverride,
    bool clearMotionOverride = false,
    ClipMotionIntensity? motionIntensity,
    bool? useStyleMotionIntensity,
    ClipTransitionType? transitionOverride,
    bool clearTransitionOverride = false,
    Duration? transitionDuration,
  }) {
    return MediaTrackClipPayload(
      mediaId: mediaId ?? this.mediaId,
      clipId: clipId ?? this.clipId,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      start: start ?? this.start,
      end: end ?? this.end,
      sourcePath: sourcePath ?? this.sourcePath,
      imageFit: imageFit ?? this.imageFit,
      cropTransform: cropTransform ?? this.cropTransform,
      caption: caption ?? this.caption,
      captionSupportingLine:
          captionSupportingLine ?? this.captionSupportingLine,
      captionSettings: captionSettings ?? this.captionSettings,
      motionOverride: clearMotionOverride
          ? null
          : motionOverride ?? this.motionOverride,
      motionIntensity: motionIntensity ?? this.motionIntensity,
      useStyleMotionIntensity:
          useStyleMotionIntensity ??
          (motionIntensity == null ? this.useStyleMotionIntensity : false),
      transitionOverride: clearTransitionOverride
          ? null
          : transitionOverride ?? this.transitionOverride,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }
}
