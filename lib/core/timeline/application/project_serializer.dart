import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';

final projectSerializerProvider = Provider<ProjectSerializer>(
  (ref) => const ProjectSerializer(),
);

class ProjectSerializer {
  const ProjectSerializer();

  static const currentSchemaVersion = 10;

  Map<String, Object?> serialize(ProjectTimeline project) {
    return {
      'schemaVersion': currentSchemaVersion,
      'id': project.id,
      'name': project.name,
      'audioSourcePath': project.audioSourcePath,
      'audioDurationMs': project.audioDuration?.inMilliseconds,
      'pacing': project.pacing.name,
      'hasManualEdits': project.hasManualEdits,
      'snapToMarkers': project.snapToMarkers,
      'audioMix': project.audioMix.toJson(),
      'template': project.template.toJson(),
      'beatMap': {
        'bpm': project.beatMap.bpm,
        'averageBeatIntervalMs':
            project.beatMap.averageBeatInterval.inMilliseconds,
        'beats': [
          for (final beat in project.beatMap.beats)
            {'timeMs': beat.time.inMilliseconds, 'strength': beat.strength},
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
                  'payload': _serializePayload(event.payload),
                },
            ],
          },
      ],
    };
  }

  ProjectTimeline deserialize(Map<String, Object?> json) {
    final version = json['schemaVersion'] as int? ?? 0;
    if (version < 0 || version > currentSchemaVersion) {
      throw FormatException('Unsupported project schema version: $version');
    }
    final beatMapJson = json['beatMap']! as Map<String, Object?>;
    final tracksJson = json['tracks']! as List<Object?>;

    return ProjectTimeline(
      id: json['id']! as String,
      name: json['name']! as String,
      audioSourcePath: json['audioSourcePath'] as String?,
      audioDuration: json['audioDurationMs'] is int
          ? Duration(milliseconds: json['audioDurationMs']! as int)
          : null,
      pacing:
          SequencePacing.values
              .where((value) => value.name == json['pacing'])
              .firstOrNull ??
          SequencePacing.balanced,
      hasManualEdits: json['hasManualEdits'] as bool? ?? true,
      snapToMarkers: json['snapToMarkers'] as bool? ?? true,
      audioMix: AudioMix.fromJson(json['audioMix']),
      template: _deserializeTemplate(json['template']),
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
        for (var i = 0; i < tracksJson.length; i++)
          _deserializeTrack(tracksJson[i]! as Map<String, Object?>, i, version),
      ],
    );
  }

  Beat _deserializeBeat(Map<String, Object?> json) {
    return Beat(
      time: Duration(milliseconds: json['timeMs']! as int),
      strength: (json['strength']! as num).toDouble(),
    );
  }

  VideoTemplate _deserializeTemplate(Object? template) {
    if (template is Map<String, Object?>) {
      return VideoTemplate.fromJson(template);
    }
    if (template is Map) {
      return VideoTemplate.fromJson(Map<String, Object?>.from(template));
    }
    if (template is String) {
      return VideoTemplates.byId(template);
    }
    return VideoTemplates.cleanMemories;
  }

  TimelineTrack _deserializeTrack(
    Map<String, Object?> json,
    int trackIndex,
    int version,
  ) {
    final events = json['events']! as List<Object?>;
    return TimelineTrack(
      id: json['id']! as String,
      name: json['name']! as String,
      events: [
        for (var i = 0; i < events.length; i++)
          _deserializeEvent(
            events[i]! as Map<String, Object?>,
            'legacy-$trackIndex-$i',
            version,
          ),
      ],
    );
  }

  BeatEvent _deserializeEvent(
    Map<String, Object?> json,
    String legacyClipId,
    int version,
  ) {
    return BeatEvent(
      time: Duration(milliseconds: json['timeMs']! as int),
      type: json['type']! as String,
      payload: _deserializePayload(json['payload'], legacyClipId, version),
    );
  }

  Object? _serializePayload(Object? payload) {
    if (payload is MediaTrackClipPayload) {
      return payload.toJson();
    }
    return payload?.toString();
  }

  Object? _deserializePayload(
    Object? payload,
    String legacyClipId,
    int version,
  ) {
    if (payload is Map<String, Object?> &&
        payload['kind'] == 'media-track-clip') {
      return MediaTrackClipPayload.fromJson(
        version < 5 && !payload.containsKey('transitionOverride')
            ? {...payload, 'transitionOverride': 'cut'}
            : payload,
        legacyClipId: legacyClipId,
      );
    }
    return payload;
  }
}
