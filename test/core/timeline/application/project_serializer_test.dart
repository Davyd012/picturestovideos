import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  group('ProjectSerializer', () {
    test('serializes and deserializes project timeline', () {
      const serializer = ProjectSerializer();
      const project = ProjectTimeline(
        id: 'project-main',
        name: 'Picture To Videos Project',
        beatMap: BeatMap(
          beats: [Beat(time: Duration(milliseconds: 200), strength: 1.5)],
          bpm: 120,
          averageBeatInterval: Duration(milliseconds: 500),
        ),
        template: VideoTemplates.cinematicDark,
        tracks: [
          TimelineTrack(
            id: 'track-markers',
            name: 'Markers',
            events: [
              BeatEvent(
                time: Duration(milliseconds: 200),
                type: 'marker',
                payload: 'Beat 1',
              ),
            ],
          ),
        ],
      );

      final json = serializer.serialize(project);
      final deserialized = serializer.deserialize(json);

      expect(deserialized.id, project.id);
      expect(deserialized.tracks.length, 1);
      expect(deserialized.tracks.first.events.first.type, 'marker');
      expect(deserialized.beatMap.bpm, 120);
      expect(deserialized.template.id, VideoTemplates.cinematicDark.id);
    });
  });
}
