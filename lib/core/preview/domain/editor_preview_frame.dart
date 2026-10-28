import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';

class EditorPreviewFrame {
  const EditorPreviewFrame({
    required this.currentTime,
    required this.activeIndex,
    required this.progress,
    required this.clips,
    this.activeClip,
    this.nextClip,
    this.transition,
    this.transitionOutgoing,
    this.transitionIncoming,
    this.transitionProgress = 0,
    this.compositionFrame,
  });

  const EditorPreviewFrame.empty()
    : currentTime = Duration.zero,
      activeIndex = -1,
      progress = 0,
      clips = const [],
      activeClip = null,
      nextClip = null,
      transition = null,
      transitionOutgoing = null,
      transitionIncoming = null,
      transitionProgress = 0,
      compositionFrame = null;

  final Duration currentTime;
  final int activeIndex;
  final double progress;
  final List<MediaTrackClipPayload> clips;
  final MediaTrackClipPayload? activeClip;
  final MediaTrackClipPayload? nextClip;
  final ClipTransition? transition;
  final MediaTrackClipPayload? transitionOutgoing;
  final MediaTrackClipPayload? transitionIncoming;
  final double transitionProgress;
  final EvaluatedCompositionFrame? compositionFrame;

  bool get hasActiveClip => activeClip != null;
}
