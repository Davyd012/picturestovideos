import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';

class MediaTrackClipPayload {
  const MediaTrackClipPayload({
    required this.mediaId,
    required this.title,
    required this.tagline,
    required this.start,
    required this.end,
    required this.sourcePath,
    required this.imageFit,
    this.cropTransform = ImageCropTransform.centered,
  });

  final String mediaId;
  final String title;
  final String tagline;
  final Duration start;
  final Duration end;
  final String sourcePath;
  final VideoTemplateImageFit imageFit;
  final ImageCropTransform cropTransform;

  Map<String, Object?> toJson() {
    return {
      'kind': 'media-track-clip',
      'mediaId': mediaId,
      'title': title,
      'tagline': tagline,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
      'sourcePath': sourcePath,
      'imageFit': imageFit.name,
      'cropTransform': cropTransform.toJson(),
    };
  }

  factory MediaTrackClipPayload.fromJson(Map<String, Object?> json) {
    return MediaTrackClipPayload(
      mediaId: json['mediaId']! as String,
      title: json['title']! as String,
      tagline: json['tagline']! as String,
      start: Duration(milliseconds: json['startMs']! as int),
      end: Duration(milliseconds: json['endMs']! as int),
      sourcePath: json['sourcePath']! as String,
      imageFit: VideoTemplateImageFit.fromJson(json['imageFit'] as String?),
      cropTransform: ImageCropTransform.fromJson(json['cropTransform']),
    );
  }

  MediaTrackClipPayload copyWith({
    String? mediaId,
    String? title,
    String? tagline,
    Duration? start,
    Duration? end,
    String? sourcePath,
    VideoTemplateImageFit? imageFit,
    ImageCropTransform? cropTransform,
  }) {
    return MediaTrackClipPayload(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      start: start ?? this.start,
      end: end ?? this.end,
      sourcePath: sourcePath ?? this.sourcePath,
      imageFit: imageFit ?? this.imageFit,
      cropTransform: cropTransform ?? this.cropTransform,
    );
  }
}
