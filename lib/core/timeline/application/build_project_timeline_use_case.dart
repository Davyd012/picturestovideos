import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

final buildProjectTimelineUseCaseProvider =
    Provider<BuildProjectTimelineUseCase>(
  (ref) => const BuildProjectTimelineUseCase(),
);

class BuildProjectTimelineUseCase {
  const BuildProjectTimelineUseCase();

  ProjectTimeline call({
    required BeatMap beatMap,
    required List<BeatEvent> events,
  }) {
    return ProjectTimeline(
      id: 'project-main',
      name: 'Picture To Videos Project',
      beatMap: beatMap,
      tracks: [
        TimelineTrack(
          id: 'track-markers',
          name: 'Markers',
          events: List.unmodifiable(events),
        ),
      ],
    );
  }
}
