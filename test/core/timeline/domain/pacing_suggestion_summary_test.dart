import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/pacing_suggestion_summary.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  test('compares changed, added and removed clip timings', () {
    final current = _project([
      _clip('first', Duration.zero, const Duration(seconds: 2)),
      _clip('old', const Duration(seconds: 2), const Duration(seconds: 4)),
    ]);
    final suggested = _project([
      _clip('first', Duration.zero, const Duration(seconds: 3)),
      _clip('new', const Duration(seconds: 3), const Duration(seconds: 5)),
    ]);

    final summary = PacingSuggestionSummary.compare(current, suggested);

    expect(summary.clipCount, 2);
    expect(summary.changedCount, 1);
    expect(summary.addedCount, 1);
    expect(summary.removedCount, 1);
    expect(summary.shortestClip, const Duration(seconds: 2));
    expect(summary.longestClip, const Duration(seconds: 3));
  });

  test('has no clip range when the suggestion has no image clips', () {
    final project = _project(const []);

    final summary = PacingSuggestionSummary.compare(project, project);

    expect(summary.clipCount, 0);
    expect(summary.shortestClip, isNull);
    expect(summary.longestClip, isNull);
  });
}

ProjectTimeline _project(List<MediaTrackClipPayload> clips) => ProjectTimeline(
  id: 'project',
  name: 'Project',
  beatMap: const BeatMap(
    beats: [],
    bpm: 0,
    averageBeatInterval: Duration(seconds: 1),
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
  ],
);

MediaTrackClipPayload _clip(
  String clipId,
  Duration start,
  Duration end, {
  String? mediaId,
}) => MediaTrackClipPayload(
  clipId: clipId,
  mediaId: mediaId ?? 'photo',
  title: clipId,
  tagline: '',
  start: start,
  end: end,
  sourcePath: 'photo.jpg',
  imageFit: VideoTemplateImageFit.cover,
);
