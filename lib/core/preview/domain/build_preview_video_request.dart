import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

class BuildPreviewVideoRequest {
  const BuildPreviewVideoRequest({
    required this.projectId,
    required this.clips,
    required this.audioSourcePath,
    required this.width,
    required this.height,
    required this.frameRate,
    this.outputFileName = 'preview.mp4',
  });

  final String projectId;
  final List<MediaTrackClipPayload> clips;
  final String? audioSourcePath;
  final int width;
  final int height;
  final int frameRate;
  final String outputFileName;
}
