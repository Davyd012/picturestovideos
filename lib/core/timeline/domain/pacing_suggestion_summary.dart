import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

/// Describes the timing impact of a proposed sequence compared with the
/// currently committed image track.
class PacingSuggestionSummary {
  const PacingSuggestionSummary({
    required this.clipCount,
    required this.changedCount,
    required this.addedCount,
    required this.removedCount,
    required this.shortestClip,
    required this.longestClip,
  });

  final int clipCount;
  final int changedCount;
  final int addedCount;
  final int removedCount;
  final Duration? shortestClip;
  final Duration? longestClip;

  factory PacingSuggestionSummary.compare(
    ProjectTimeline current,
    ProjectTimeline suggested,
  ) {
    final currentClips = _clips(current);
    final suggestedClips = _clips(suggested);
    final currentById = {for (final clip in currentClips) clip.clipId: clip};
    final suggestedIds = suggestedClips.map((clip) => clip.clipId).toSet();
    final durations = suggestedClips
        .map((clip) => clip.end - clip.start)
        .toList();

    return PacingSuggestionSummary(
      clipCount: suggestedClips.length,
      changedCount: suggestedClips.where((clip) {
        final old = currentById[clip.clipId];
        return old != null && (old.start != clip.start || old.end != clip.end);
      }).length,
      addedCount: suggestedClips
          .where((clip) => !currentById.containsKey(clip.clipId))
          .length,
      removedCount: currentClips
          .where((clip) => !suggestedIds.contains(clip.clipId))
          .length,
      shortestClip: durations.isEmpty
          ? null
          : durations.reduce((left, right) => left < right ? left : right),
      longestClip: durations.isEmpty
          ? null
          : durations.reduce((left, right) => left > right ? left : right),
    );
  }

  static List<MediaTrackClipPayload> _clips(ProjectTimeline project) => [
    for (final track in project.tracks)
      if (track.id == 'track-media')
        for (final event in track.events)
          if (event.payload is MediaTrackClipPayload)
            event.payload as MediaTrackClipPayload,
  ];
}
