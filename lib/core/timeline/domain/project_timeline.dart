import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

class ProjectTimeline {
  const ProjectTimeline({
    required this.id,
    required this.name,
    required this.beatMap,
    required this.tracks,
    this.template = VideoTemplates.cleanMemories,
  });

  final String id;
  final String name;
  final BeatMap beatMap;
  final List<TimelineTrack> tracks;
  final VideoTemplate template;

  ProjectTimeline copyWith({
    String? id,
    String? name,
    BeatMap? beatMap,
    List<TimelineTrack>? tracks,
    VideoTemplate? template,
  }) {
    return ProjectTimeline(
      id: id ?? this.id,
      name: name ?? this.name,
      beatMap: beatMap ?? this.beatMap,
      tracks: tracks ?? this.tracks,
      template: template ?? this.template,
    );
  }
}
