import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';

class BuildPreviewVideoRequest {
  const BuildPreviewVideoRequest({
    required this.projectId,
    required this.clips,
    required this.audioSourcePath,
    required this.width,
    required this.height,
    required this.frameRate,
    this.template = VideoTemplates.cleanMemories,
    this.outputFileName = 'preview.mp4',
    this.includeThumbnails = false,
    this.audioMix = const AudioMix(),
    this.audioSourceDuration,
  });

  final String projectId;
  final List<MediaTrackClipPayload> clips;
  final String? audioSourcePath;
  final int width;
  final int height;
  final int frameRate;
  final VideoTemplate template;
  final String outputFileName;
  final bool includeThumbnails;
  final AudioMix audioMix;
  final Duration? audioSourceDuration;

  /// Canonical immutable render input. Legacy call sites may still provide
  /// clip payloads; conversion happens here before either renderer consumes it.
  VideoComposition get composition => VideoComposition(
    clips: List.unmodifiable([
      for (final clip in clips) CompositionClip.fromPayload(clip, template),
    ]),
    width: width,
    height: height,
    frameRate: frameRate,
    template: template,
    audioMix: audioMix,
    audioSourcePath: audioSourcePath,
    audioSourceDuration: audioSourceDuration,
  ).quantizedForOutput();

  List<MediaTrackClipPayload> get resolvedClips => List.unmodifiable([
    for (final clip in composition.clips) clip.toPayload(),
  ]);
}
