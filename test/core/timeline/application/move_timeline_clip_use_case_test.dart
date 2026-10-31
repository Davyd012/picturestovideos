import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/move_timeline_clip_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  const move = MoveTimelineClipUseCase();
  final clips = List.generate(
    56,
    (i) => MediaTrackClipPayload(
      clipId: '$i',
      mediaId: 'same',
      title: '$i',
      tagline: '',
      start: Duration(seconds: i * 4),
      end: Duration(seconds: i * 4 + 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
      caption: 'caption $i',
    ),
  );
  final project = ProjectTimeline(
    id: 'project',
    name: 'project',
    beatMap: const BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 2),
    ),
    tracks: [
      TimelineTrack(
        id: 'track-media',
        name: 'Images',
        events: [
          for (final clip in clips)
            BeatEvent(time: clip.start, type: 'image', payload: clip),
        ],
      ),
      const TimelineTrack(
        id: 'track-markers',
        name: 'Markers',
        events: [BeatEvent(time: Duration(seconds: 1), type: 'marker')],
      ),
    ],
  );
  test(
    'moves final occurrences into existing slots with edits and gaps intact',
    () {
      final moved = move(project, '55', 1);
      final result = moved.tracks.first.events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(result.first.clipId, '55');
      expect(result.first.caption, 'caption 55');
      expect(result[55].clipId, '54');
      for (var i = 0; i < result.length; i++) {
        expect(result[i].start, clips[i].start);
        expect(result[i].end, clips[i].end);
      }
      expect(moved.videoDuration, project.videoDuration);
      expect(moved.tracks.last, same(project.tracks.last));
      expect(moved.hasManualEdits, isTrue);
      const serializer = ProjectSerializer();
      final reopened = serializer.deserialize(serializer.serialize(moved));
      final restored =
          reopened.tracks.first.events.first.payload as MediaTrackClipPayload;
      expect(restored.clipId, '55');
      expect(restored.caption, 'caption 55');
      expect(restored.start, clips.first.start);
      expect(restored.end, clips.first.end);
      final back = move(moved, '55', 56);
      expect(
        (back.tracks.first.events.last.payload as MediaTrackClipPayload).clipId,
        '55',
      );
      expect(
        (move(project, '54', 56).tracks.first.events.last.payload
                as MediaTrackClipPayload)
            .clipId,
        '54',
      );
    },
  );
  test('rejects invalid positions, missing IDs and no-op moves', () {
    expect(move(project, '55', 0), same(project));
    expect(move(project, '55', 57), same(project));
    expect(move(project, 'missing', 1), same(project));
    expect(move(project, '55', 56), same(project));
  });
}
