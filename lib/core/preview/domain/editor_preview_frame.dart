import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

class EditorPreviewFrame {
  const EditorPreviewFrame({
    required this.currentTime,
    required this.activeIndex,
    required this.progress,
    required this.clips,
    this.activeClip,
    this.nextClip,
  });

  const EditorPreviewFrame.empty()
    : currentTime = Duration.zero,
      activeIndex = -1,
      progress = 0,
      clips = const [],
      activeClip = null,
      nextClip = null;

  final Duration currentTime;
  final int activeIndex;
  final double progress;
  final List<MediaTrackClipPayload> clips;
  final MediaTrackClipPayload? activeClip;
  final MediaTrackClipPayload? nextClip;

  bool get hasActiveClip => activeClip != null;
}
