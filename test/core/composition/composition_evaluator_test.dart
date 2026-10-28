import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/composition/domain/frame_time_quantizer.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  const evaluator = CompositionEvaluator();

  test('quantizes timestamps to the nearest output frame', () {
    const quantizer = FrameTimeQuantizer(30);
    expect(
      quantizer.quantize(const Duration(microseconds: 16000)),
      const Duration(microseconds: 0),
    );
    expect(
      quantizer.quantize(const Duration(microseconds: 17000)),
      const Duration(microseconds: 33333),
    );
    expect(
      quantizer.quantize(const Duration(microseconds: -17000)),
      const Duration(microseconds: -33333),
    );
  });

  test('motion progress follows the encoded frame indices', () {
    const quantizer = FrameTimeQuantizer(30);
    expect(quantizer.frameCountForDuration(const Duration(seconds: 1)), 30);
    final lastFrameTime = quantizer.quantize(
      const Duration(microseconds: 29 * Duration.microsecondsPerSecond ~/ 30),
    );
    expect(
      quantizer.progressForFrame(
        time: Duration.zero,
        start: Duration.zero,
        end: const Duration(seconds: 1),
      ),
      0,
    );
    expect(
      quantizer.progressForFrame(
        time: lastFrameTime,
        start: Duration.zero,
        end: const Duration(seconds: 1),
      ),
      1,
    );
  });

  test('empty compositions validate and evaluate to no frames', () {
    final composition = _composition(const []);

    expect(composition.duration, Duration.zero);
    expect(
      composition.validate().map((failure) => failure.code),
      contains(CompositionValidationCode.emptyComposition),
    );
    expect(evaluator.evaluate(composition, Duration.zero).layers, isEmpty);
  });

  test(
    'a single clip holds its first frame and ends on a half-open boundary',
    () {
      final composition = _composition([_clip('only', start: 500, end: 1500)]);

      final beforeStart = evaluator.evaluate(composition, Duration.zero);
      final firstFrame = evaluator.evaluate(
        composition,
        const Duration(milliseconds: 500),
      );
      final lastFrame = evaluator.evaluate(
        composition,
        const Duration(milliseconds: 1467),
      );
      final atEnd = evaluator.evaluate(
        composition,
        const Duration(milliseconds: 1500),
      );

      expect(beforeStart.layers.single.clip.clipId, 'only');
      expect(beforeStart.layers.single.progress, 0);
      expect(firstFrame.layers.single.progress, 0);
      expect(lastFrame.layers.single.progress, 1);
      expect(atEnd.layers, isEmpty);
    },
  );

  test(
    'normalizes clip cuts and transition duration to the same frame grid',
    () {
      final composition = _composition([
        _clip(
          'one',
          start: 0,
          end: 1001,
          transition: ClipTransitionType.dissolve,
        ).copyWith(transitionDuration: const Duration(milliseconds: 601)),
        _clip('two', start: 1001, end: 2001),
      ]).quantizedForOutput();

      expect(composition.clips.first.end, const Duration(seconds: 1));
      expect(composition.clips.last.start, const Duration(seconds: 1));
      expect(
        composition.clips.first.transitionDuration,
        const Duration(milliseconds: 600),
      );
      expect(composition.validate(), isEmpty);
    },
  );

  test('evaluator resolves transitions from normalized clip boundaries', () {
    final composition = _composition([
      _clip(
        'one',
        start: 0,
        end: 1025,
        transition: ClipTransitionType.dissolve,
      ).copyWith(transitionDuration: const Duration(milliseconds: 601)),
      _clip('two', start: 1025, end: 2025),
    ], frameRate: 10);

    final before = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 649),
    );
    final atStart = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 700),
    );
    final middle = evaluator.evaluate(composition, const Duration(seconds: 1));

    expect(before.layers, hasLength(1));
    expect(atStart.layers, hasLength(2));
    expect(atStart.transitionProgress, 0);
    expect(middle.transitionProgress, closeTo(0.5, 0.02));
  });

  test('dissolve exposes outgoing then incoming around a fixed cut', () {
    final composition = _composition([
      _clip(
        'one',
        start: 0,
        end: 1000,
        transition: ClipTransitionType.dissolve,
      ),
      _clip('two', start: 1000, end: 2000),
    ]);

    final before = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 666),
    );
    final middle = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1000),
    );
    final after = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1300),
    );

    expect(before.layers.single.clip.clipId, 'one');
    expect(middle.layers.map((layer) => layer.clip.clipId), ['one', 'two']);
    expect(middle.transitionProgress, closeTo(0.5, 0.02));
    expect(middle.layers.last.captionFrame.visible, isTrue);
    expect(middle.layers.last.captionLayout.width, composition.width);
    expect(middle.layers.last.motionZoom, greaterThanOrEqualTo(1));
    expect(middle.layers.last.clip.imageFit, VideoTemplateImageFit.cover);
    expect(middle.audioGain, 1);
    expect(after.layers.single.clip.clipId, 'two');
  });

  test('a hard cut belongs to incoming half-open clip interval', () {
    final composition = _composition([
      _clip('one', start: 0, end: 1000),
      _clip('two', start: 1000, end: 2000),
    ]);
    final frame = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1000),
    );
    expect(frame.layers.single.clip.clipId, 'two');
  });

  test('last encoded clip frame reaches the motion endpoint', () {
    final frame = evaluator.evaluate(
      _composition([_clip('one', start: 0, end: 1000)]),
      const Duration(microseconds: 29 * Duration.microsecondsPerSecond ~/ 30),
    );
    expect(frame.layers.single.progress, 1);
    expect(frame.layers.single.motionZoom, 1);
  });

  test('evaluates raw cut timestamps on the normalized output frame grid', () {
    final composition = _composition([
      _clip('one', start: 0, end: 1025),
      _clip('two', start: 1025, end: 2025),
    ], frameRate: 10);

    final before = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 949),
    );
    final at = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 951),
    );
    final after = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1050),
    );

    expect(before.time, const Duration(milliseconds: 900));
    expect(before.layers.single.clip.clipId, 'one');
    expect(at.time, const Duration(seconds: 1));
    expect(at.layers.single.clip.clipId, 'two');
    expect(after.layers.single.clip.clipId, 'two');
  });

  test('transition uses frame-quantized start and end ownership', () {
    final composition = _composition([
      _clip(
        'one',
        start: 0,
        end: 1000,
        transition: ClipTransitionType.dissolve,
      ),
      _clip('two', start: 1000, end: 2000),
    ], frameRate: 10);
    final beforeStart = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 649),
    );
    final atStart = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 700),
    );
    final afterStart = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 750),
    );
    final beforeEnd = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1249),
    );
    final atEnd = evaluator.evaluate(
      composition,
      const Duration(milliseconds: 1300),
    );

    expect(beforeStart.layers.single.clip.clipId, 'one');
    expect(atStart.layers, hasLength(2));
    expect(atStart.transitionProgress, 0);
    expect(afterStart.transitionProgress, greaterThan(0));
    expect(beforeEnd.layers, hasLength(2));
    expect(atEnd.layers.single.clip.clipId, 'two');
    expect(
      evaluator.evaluate(composition, const Duration(seconds: 2)).layers,
      isEmpty,
    );
  });

  test('permits gaps and repeated sources with distinct clip IDs', () {
    final composition = _composition([
      _clip('occurrence-a', source: 'same.jpg', start: 0, end: 1000),
      _clip('occurrence-b', source: 'same.jpg', start: 1500, end: 2000),
    ]);
    expect(composition.validate(), isEmpty);
    expect(
      evaluator
          .evaluate(composition, const Duration(milliseconds: 1200))
          .layers
          .single
          .clip
          .clipId,
      'occurrence-a',
    );
  });

  test('conversion freezes committed clip identity independent of markers', () {
    const beatMap = BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(milliseconds: 500),
    );
    final committed = [
      _clip(
        'same-source-a',
        source: 'same.jpg',
        start: 0,
        end: 1000,
      ).toPayload(),
      _clip(
        'same-source-b',
        source: 'same.jpg',
        start: 1000,
        end: 2000,
      ).toPayload(),
    ];
    final first = VideoComposition.fromProject(
      project: _project(beatMap, const [
        BeatEvent(time: Duration.zero, type: 'beat', payload: 'old'),
      ]),
      committedClips: committed,
      width: 1280,
      height: 720,
      frameRate: 30,
    );
    final afterMarkerEdit = VideoComposition.fromProject(
      project: _project(beatMap, const [
        BeatEvent(time: Duration(seconds: 3), type: 'beat', payload: 'new'),
      ]),
      committedClips: committed,
      width: 1280,
      height: 720,
      frameRate: 30,
    );

    expect(first.clips.map((clip) => clip.clipId), [
      'same-source-a',
      'same-source-b',
    ]);
    expect(afterMarkerEdit.clips.map((clip) => clip.start), [
      Duration.zero,
      const Duration(seconds: 1),
    ]);
    expect(() => first.clips.add(first.clips.first), throwsUnsupportedError);
  });

  test('reports typed failures without inventing composition timing', () {
    final composition = _composition(
      [
        _clip(
          '',
          source: '',
          start: 0,
          end: 500,
        ).copyWith(transitionDuration: const Duration(seconds: 6)),
        _clip('same', start: 400, end: 1000),
        _clip('same', start: 1000, end: 1500),
        _clip('invalid-span', start: 1500, end: 1400),
      ],
      width: 0,
      frameRate: 0,
      audioMix: const AudioMix(start: Duration(seconds: -1)),
    );

    final codes = composition.validate().map((failure) => failure.code);
    expect(codes, contains(CompositionValidationCode.invalidOutputSize));
    expect(codes, contains(CompositionValidationCode.invalidFrameRate));
    expect(codes, contains(CompositionValidationCode.emptyClipId));
    expect(codes, contains(CompositionValidationCode.duplicateClipId));
    expect(codes, contains(CompositionValidationCode.emptySource));
    expect(codes, contains(CompositionValidationCode.overlappingClips));
    expect(codes, contains(CompositionValidationCode.invalidTransition));
    expect(codes, contains(CompositionValidationCode.invalidAudioRange));
    expect(codes, contains(CompositionValidationCode.invalidClipSpan));
  });
}

VideoComposition _composition(
  List<CompositionClip> clips, {
  int width = 1280,
  AudioMix audioMix = const AudioMix(),
  int frameRate = 30,
}) => VideoComposition(
  clips: List.unmodifiable(clips),
  width: width,
  height: 720,
  frameRate: frameRate,
  template: VideoTemplates.cleanMemories,
  audioMix: audioMix,
);

ProjectTimeline _project(BeatMap beatMap, List<BeatEvent> markers) =>
    ProjectTimeline(
      id: 'project',
      name: 'Project',
      beatMap: beatMap,
      tracks: [
        TimelineTrack(id: 'track-markers', name: 'Markers', events: markers),
      ],
    );

CompositionClip _clip(
  String id, {
  String source = 'image.jpg',
  required int start,
  required int end,
  ClipTransitionType transition = ClipTransitionType.cut,
}) => CompositionClip(
  clipId: id,
  mediaId: source,
  title: id,
  tagline: '',
  sourcePath: source,
  start: Duration(milliseconds: start),
  end: Duration(milliseconds: end),
  imageFit: VideoTemplateImageFit.cover,
  cropTransform: ImageCropTransform.centered,
  motion: const ClipMotion(
    preset: ClipMotionPreset.none,
    intensity: ClipMotionIntensity.subtle,
  ),
  caption: '',
  captionSupportingLine: '',
  captionSettings: const CaptionSettings(),
  transitionType: transition,
  transitionDuration: const Duration(milliseconds: 600),
);
