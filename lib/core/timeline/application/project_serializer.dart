import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

final projectSerializerProvider = Provider<ProjectSerializer>(
  (ref) => const ProjectSerializer(),
);

class ProjectSerializer {
  const ProjectSerializer();

  Map<String, Object?> serialize(ProjectTimeline project) {
    return {
      'id': project.id,
      'name': project.name,
      'beatMap': {
        'bpm': project.beatMap.bpm,
        'averageBeatIntervalMs': project.beatMap.averageBeatInterval.inMilliseconds,
        'beats': [
          for (final beat in project.beatMap.beats)
            {
              'timeMs': beat.time.inMilliseconds,
              'strength': beat.strength,
            },
        ],
      },
      'tracks': [
        for (final track in project.tracks)
          {
            'id': track.id,
            'name': track.name,
            'events': [
              for (final event in track.events)
                {
                  'timeMs': event.time.inMilliseconds,
                  'type': event.type,
                  'payload': event.payload?.toString(),
                },
            ],
          },
      ],
    };
  }

  ProjectTimeline deserialize(Map<String, Object?> json) {
    final beatMapJson = json['beatMap']! as Map<String, Object?>;
    final tracksJson = json['tracks']! as List<Object?>;

    return ProjectTimeline(
      id: json['id']! as String,
      name: json['name']! as String,
      beatMap: BeatMap(
        beats: [
          for (final beatJson in beatMapJson['beats']! as List<Object?>)
            _deserializeBeat(beatJson! as Map<String, Object?>),
        ],
        bpm: (beatMapJson['bpm']! as num).toDouble(),
        averageBeatInterval: Duration(
          milliseconds: beatMapJson['averageBeatIntervalMs']! as int,
        ),
      ),
      tracks: [
        for (final trackJson in tracksJson)
          _deserializeTrack(trackJson! as Map<String, Object?>),
      ],
    );
  }

  Beat _deserializeBeat(Map<String, Object?> json) {
    return Beat(
      time: Duration(milliseconds: json['timeMs']! as int),
      strength: (json['strength']! as num).toDouble(),
    );
  }

  TimelineTrack _deserializeTrack(Map<String, Object?> json) {
    return TimelineTrack(
      id: json['id']! as String,
      name: json['name']! as String,
      events: [
        for (final eventJson in json['events']! as List<Object?>)
          _deserializeEvent(eventJson! as Map<String, Object?>),
      ],
    );
  }

  BeatEvent _deserializeEvent(Map<String, Object?> json) {
    return BeatEvent(
      time: Duration(milliseconds: json['timeMs']! as int),
      type: json['type']! as String,
      payload: json['payload'],
    );
  }
}
