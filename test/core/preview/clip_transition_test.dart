import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

void main() {
  const first = MediaTrackClipPayload(
    clipId: 'first',
    mediaId: 'same',
    title: '',
    tagline: '',
    start: Duration.zero,
    end: Duration(seconds: 3),
    sourcePath: '',
    imageFit: VideoTemplateImageFit.cover,
    transitionOverride: ClipTransitionType.dissolve,
    transitionDuration: Duration(seconds: 1),
  );
  final next = first.copyWith(
    clipId: 'second',
    start: const Duration(seconds: 3),
    end: const Duration(seconds: 5),
  );

  test('centers a transition without moving the boundary', () {
    final transition = ClipTransition.between(
      first,
      next,
      VideoTemplates.cleanMemories,
    );
    expect(transition.start, const Duration(milliseconds: 2500));
    expect(transition.boundary, const Duration(seconds: 3));
    expect(transition.end, const Duration(milliseconds: 3500));
    expect(transition.progressAt(const Duration(seconds: 3)), 0.5);
    expect(transition.wasClamped, isFalse);
  });

  test('clamps short clips and does not overlap separate boundaries', () {
    final short = next.copyWith(end: const Duration(milliseconds: 3200));
    final transition = ClipTransition.between(
      first,
      short,
      VideoTemplates.cleanMemories,
    );
    expect(transition.duration, const Duration(milliseconds: 200));
    expect(transition.wasClamped, isTrue);
    expect(transition.start, const Duration(milliseconds: 2900));
    expect(transition.end, const Duration(milliseconds: 3100));
  });

  test('cut and gaps do not invent overlapping frames', () {
    expect(
      ClipTransition.between(
        first.copyWith(transitionOverride: ClipTransitionType.cut),
        next,
        VideoTemplates.cleanMemories,
      ).duration,
      Duration.zero,
    );
    expect(
      ClipTransition.between(
        first,
        next.copyWith(start: const Duration(seconds: 4)),
        VideoTemplates.cleanMemories,
      ).duration,
      Duration.zero,
    );
  });

  test('transition overrides survive serialization', () {
    final restored = MediaTrackClipPayload.fromJson(first.toJson());
    expect(restored.transitionOverride, ClipTransitionType.dissolve);
    expect(restored.transitionDuration, const Duration(seconds: 1));
  });

  test(
    'preview resolves both images at the boundary and holds through gaps',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const beatMap = BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 1),
      );
      ProjectTimeline projectWith(MediaTrackClipPayload incoming) =>
          ProjectTimeline(
            id: 'p',
            name: 'p',
            beatMap: beatMap,
            tracks: [
              TimelineTrack(
                id: 'track-media',
                name: 'Images',
                events: [
                  const BeatEvent(
                    time: Duration.zero,
                    type: 'image',
                    payload: first,
                  ),
                  BeatEvent(
                    time: incoming.start,
                    type: 'image',
                    payload: incoming,
                  ),
                ],
              ),
            ],
          );
      final resolve = container.read(resolveEditorPreviewFrameUseCaseProvider);
      final boundary = resolve(
        beatMap: beatMap,
        project: projectWith(next),
        currentTime: const Duration(seconds: 3),
      );
      expect(boundary.transitionOutgoing?.clipId, 'first');
      expect(boundary.transitionIncoming?.clipId, 'second');
      expect(boundary.transitionProgress, 0.5);
      final gap = resolve(
        beatMap: beatMap,
        project: projectWith(next.copyWith(start: const Duration(seconds: 4))),
        currentTime: const Duration(milliseconds: 3500),
      );
      expect(gap.activeClip?.clipId, 'first');
      expect(gap.transition, isNull);
    },
  );
}
