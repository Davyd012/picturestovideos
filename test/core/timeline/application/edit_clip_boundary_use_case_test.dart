import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/edit_clip_boundary_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';

void main() {
  const first = MediaTrackClipPayload(
    clipId: 'one',
    mediaId: 'photo',
    title: '',
    tagline: '',
    start: Duration.zero,
    end: Duration(seconds: 3),
    sourcePath: '',
    imageFit: VideoTemplateImageFit.cover,
    caption: 'First',
  );
  const second = MediaTrackClipPayload(
    clipId: 'two',
    mediaId: 'photo',
    title: '',
    tagline: '',
    start: Duration(seconds: 3),
    end: Duration(seconds: 6),
    sourcePath: '',
    imageFit: VideoTemplateImageFit.cover,
    caption: 'Second',
  );
  const project = ProjectTimeline(
    id: 'p',
    name: 'P',
    beatMap: BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 1),
    ),
    tracks: [
      TimelineTrack(
        id: 'track-markers',
        name: 'Markers',
        events: [BeatEvent(time: Duration(milliseconds: 4100), type: 'marker')],
      ),
      TimelineTrack(
        id: 'track-media',
        name: 'Images',
        events: [
          BeatEvent(time: Duration.zero, type: 'image', payload: first),
          BeatEvent(time: Duration(seconds: 3), type: 'image', payload: second),
        ],
      ),
    ],
  );
  const edit = EditClipBoundaryUseCase();
  test('snap preference persists with the project', () {
    final saved = project.copyWith(snapToMarkers: false);
    final restored = const ProjectSerializer().deserialize(
      const ProjectSerializer().serialize(saved),
    );
    expect(restored.snapToMarkers, isFalse);
  });
  List<MediaTrackClipPayload> clips(ProjectTimeline value) => value
      .tracks
      .last
      .events
      .map((event) => event.payload as MediaTrackClipPayload)
      .toList();

  test(
    'snaps one boundary and preserves later timing, markers and clip edits',
    () {
      final updated = edit(
        project: project,
        clipId: 'one',
        duration: const Duration(seconds: 4),
        snap: true,
      );
      expect(clips(updated).first.end, const Duration(milliseconds: 4100));
      expect(clips(updated).last.start, const Duration(milliseconds: 4100));
      expect(clips(updated).last.end, const Duration(seconds: 6));
      expect(clips(updated).map((clip) => clip.clipId), ['one', 'two']);
      expect(clips(updated).map((clip) => clip.caption), ['First', 'Second']);
      expect(
        updated.tracks.first.events.single.time,
        const Duration(milliseconds: 4100),
      );
      expect(updated.hasManualEdits, isTrue);
      final restored = const ProjectSerializer().deserialize(
        const ProjectSerializer().serialize(updated),
      );
      expect(clips(restored).last.start, const Duration(milliseconds: 4100));
    },
  );

  test(
    'can disable snapping and clamps without making a zero-length neighbor',
    () {
      final unsnapped = edit(
        project: project,
        clipId: 'one',
        duration: const Duration(seconds: 4),
        snap: false,
      );
      expect(clips(unsnapped).last.start, const Duration(seconds: 4));
      final clamped = edit(
        project: project,
        clipId: 'one',
        duration: const Duration(seconds: 10),
        snap: true,
      );
      expect(clips(clamped).last.start, const Duration(milliseconds: 5900));
      expect(clips(clamped).last.end, const Duration(seconds: 6));
    },
  );
}
