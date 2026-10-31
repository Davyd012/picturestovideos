import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

/// Moves an occurrence between existing time slots without changing boundaries.
class MoveTimelineClipUseCase {
  const MoveTimelineClipUseCase();

  ProjectTimeline call(ProjectTimeline project, String clipId, int position) {
    final tracks = project.tracks.where((track) => track.id == 'track-media');
    if (tracks.length != 1 || clipId.isEmpty) return project;
    final track = tracks.single;
    final slots =
        track.events
            .where((event) => event.payload is MediaTrackClipPayload)
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final clips = slots
        .map((event) => event.payload as MediaTrackClipPayload)
        .toList();
    final matches = clips.where((clip) => clip.clipId == clipId);
    if (matches.length != 1 || position < 1 || position > clips.length) {
      return project;
    }
    final from = clips.indexWhere((clip) => clip.clipId == clipId);
    final to = position - 1;
    if (from == to) return project;
    clips.insert(to, clips.removeAt(from));
    final replacements = <BeatEvent, BeatEvent>{};
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final boundary = slot.payload as MediaTrackClipPayload;
      replacements[slot] = BeatEvent(
        time: slot.time,
        type: slot.type,
        payload: clips[i].copyWith(start: boundary.start, end: boundary.end),
      );
    }
    return project.copyWith(
      hasManualEdits: true,
      tracks: List.unmodifiable([
        for (final item in project.tracks)
          if (identical(item, track))
            item.copyWith(
              events: List.unmodifiable([
                for (final event in item.events) replacements[event] ?? event,
              ]),
            )
          else
            item,
      ]),
    );
  }
}
