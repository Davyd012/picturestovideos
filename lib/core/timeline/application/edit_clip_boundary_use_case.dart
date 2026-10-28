import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

class EditClipBoundaryUseCase {
  const EditClipBoundaryUseCase();
  static const minimumClipDuration = Duration(milliseconds: 100);
  static const snapTolerance = Duration(milliseconds: 250);
  static const maximumEnd = Duration(hours: 24);

  ProjectTimeline call({
    required ProjectTimeline project,
    required String clipId,
    required Duration duration,
    required bool snap,
  }) {
    final media = project.tracks
        .where((track) => track.id == 'track-media')
        .firstOrNull;
    if (media == null) return project;
    final events = [...media.events]..sort((a, b) => a.time.compareTo(b.time));
    final index = events.indexWhere(
      (event) =>
          event.payload is MediaTrackClipPayload &&
          (event.payload as MediaTrackClipPayload).clipId == clipId,
    );
    if (index < 0) return project;
    final clip = events[index].payload as MediaTrackClipPayload;
    final nextEvent = index + 1 < events.length ? events[index + 1] : null;
    final nextClip = nextEvent?.payload is MediaTrackClipPayload
        ? nextEvent!.payload as MediaTrackClipPayload
        : null;
    final max = nextClip == null
        ? maximumEnd
        : nextClip.end - minimumClipDuration;
    final min = clip.start + minimumClipDuration;
    if (max < min) return project;
    var desired = clip.start + duration;
    if (desired < min) desired = min;
    if (desired > max) desired = max;
    if (snap) {
      Duration? nearest;
      var distance = snapTolerance + const Duration(microseconds: 1);
      for (final track in project.tracks) {
        if (track.id != 'track-markers') continue;
        for (final marker in track.events) {
          if (marker.time < min || marker.time > max) continue;
          final delta = marker.time - desired;
          final absolute = delta.isNegative ? -delta : delta;
          if (absolute <= snapTolerance && absolute < distance) {
            nearest = marker.time;
            distance = absolute;
          }
        }
      }
      desired = nearest ?? desired;
    }
    if (clip.end == desired &&
        (nextClip == null || nextEvent!.time == desired)) {
      return project;
    }
    events[index] = BeatEvent(
      time: events[index].time,
      type: events[index].type,
      payload: clip.copyWith(end: desired),
    );
    if (nextClip != null) {
      events[index + 1] = BeatEvent(
        time: desired,
        type: nextEvent!.type,
        payload: nextClip.copyWith(start: desired),
      );
    }
    return project.copyWith(
      hasManualEdits: true,
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id == 'track-media')
            track.copyWith(events: List.unmodifiable(events))
          else
            track,
      ]),
    );
  }
}
