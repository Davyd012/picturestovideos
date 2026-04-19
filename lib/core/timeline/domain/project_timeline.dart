import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

class ProjectTimeline {
  const ProjectTimeline({
    required this.id,
    required this.name,
    required this.beatMap,
    required this.tracks,
  });

  final String id;
  final String name;
  final BeatMap beatMap;
  final List<TimelineTrack> tracks;

  ProjectTimeline copyWith({
    String? id,
    String? name,
    BeatMap? beatMap,
    List<TimelineTrack>? tracks,
  }) {
    return ProjectTimeline(
      id: id ?? this.id,
      name: name ?? this.name,
      beatMap: beatMap ?? this.beatMap,
      tracks: tracks ?? this.tracks,
    );
  }
}
