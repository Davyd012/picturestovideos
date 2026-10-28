import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

class ProjectTimeline {
  const ProjectTimeline({
    required this.id,
    required this.name,
    required this.beatMap,
    required this.tracks,
    this.template = VideoTemplates.calmMemories,
    this.audioSourcePath,
    this.audioDuration,
    this.pacing = SequencePacing.balanced,
    this.hasManualEdits = false,
    this.snapToMarkers = true,
    this.audioMix = const AudioMix(),
  });

  final String id;
  final String name;
  final BeatMap beatMap;
  final List<TimelineTrack> tracks;
  final VideoTemplate template;
  final String? audioSourcePath;
  final Duration? audioDuration;
  final SequencePacing pacing;
  final bool hasManualEdits;
  final bool snapToMarkers;
  final AudioMix audioMix;

  Duration? get videoDuration {
    Duration? end;
    for (final track in tracks) {
      if (track.id != 'track-media') continue;
      for (final event in track.events) {
        final clip = event.payload;
        if (clip is MediaTrackClipPayload && (end == null || clip.end > end)) {
          end = clip.end;
        }
      }
    }
    return end;
  }

  ProjectTimeline copyWith({
    String? id,
    String? name,
    BeatMap? beatMap,
    List<TimelineTrack>? tracks,
    VideoTemplate? template,
    String? audioSourcePath,
    Duration? audioDuration,
    SequencePacing? pacing,
    bool? hasManualEdits,
    bool? snapToMarkers,
    AudioMix? audioMix,
  }) {
    return ProjectTimeline(
      id: id ?? this.id,
      name: name ?? this.name,
      beatMap: beatMap ?? this.beatMap,
      tracks: tracks ?? this.tracks,
      template: template ?? this.template,
      audioSourcePath: audioSourcePath ?? this.audioSourcePath,
      audioDuration: audioDuration ?? this.audioDuration,
      pacing: pacing ?? this.pacing,
      hasManualEdits: hasManualEdits ?? this.hasManualEdits,
      snapToMarkers: snapToMarkers ?? this.snapToMarkers,
      audioMix: audioMix ?? this.audioMix,
    );
  }
}
