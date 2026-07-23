import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

void main() {
  test('crop transform clamps values', () {
    final transform = ImageCropTransform.centered.copyWith(
      focalX: 2,
      focalY: -2,
      zoom: 9,
    );

    expect(transform.focalX, 1);
    expect(transform.focalY, -1);
    expect(transform.zoom, ImageCropTransform.maxZoom);
  });

  test('media payload round-trips crop transform and defaults older JSON', () {
    const payload = MediaTrackClipPayload(
      mediaId: 'image',
      title: 'Image',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 2),
      sourcePath: '/tmp/image.jpg',
      imageFit: VideoTemplateImageFit.cover,
      cropTransform: ImageCropTransform(focalX: 0.25, focalY: -0.5, zoom: 2),
    );

    expect(
      MediaTrackClipPayload.fromJson(payload.toJson()).cropTransform,
      payload.cropTransform,
    );
    final legacyJson = payload.toJson()..remove('cropTransform');
    expect(
      MediaTrackClipPayload.fromJson(legacyJson).cropTransform,
      ImageCropTransform.centered,
    );
  });
}
