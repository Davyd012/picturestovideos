import 'dart:math' as math;

import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

enum ClipTransitionType {
  cut,
  dissolve,
  slide,
  zoom;

  static ClipTransitionType fromTemplate(VideoTemplateTransition transition) =>
      switch (transition) {
        VideoTemplateTransition.hardCut => cut,
        VideoTemplateTransition.slideLeft => slide,
        VideoTemplateTransition.fade ||
        VideoTemplateTransition.crossfade => dissolve,
      };
}

/// A boundary is centered on the next clip's start. Adjacent still frames can
/// be held outside their nominal span; the music and clip boundaries never move.
class ClipTransition {
  const ClipTransition({
    required this.type,
    required this.requestedDuration,
    required this.duration,
    required this.boundary,
  });
  final ClipTransitionType type;
  final Duration requestedDuration;
  final Duration duration;
  final Duration boundary;

  bool get wasClamped =>
      duration < requestedDuration && type != ClipTransitionType.cut;
  Duration get start => boundary - duration ~/ 2;
  Duration get end => start + duration;

  double progressAt(Duration time) {
    if (duration <= Duration.zero) return time < boundary ? 0 : 1;
    return ((time - start).inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  static ClipTransition between(
    MediaTrackClipPayload outgoing,
    MediaTrackClipPayload incoming,
    VideoTemplate template,
  ) {
    final type =
        outgoing.transitionOverride ??
        ClipTransitionType.fromTemplate(template.transition);
    final requested = outgoing.transitionDuration;
    final left = outgoing.end - outgoing.start;
    final right = incoming.end - incoming.start;
    // Non-adjacent clips have no unambiguous shared boundary.
    final availableMicros =
        outgoing.end == incoming.start &&
            left > Duration.zero &&
            right > Duration.zero
        ? math.min(left.inMicroseconds, right.inMicroseconds)
        : 0;
    final safeRequested = math.max(0, requested.inMicroseconds);
    final actual = type == ClipTransitionType.cut
        ? 0
        : math.min(safeRequested, availableMicros);
    return ClipTransition(
      type: type,
      requestedDuration: requested,
      duration: Duration(microseconds: actual),
      boundary: incoming.start,
    );
  }
}
