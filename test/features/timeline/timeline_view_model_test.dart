import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test('bulk transitions only affect boundaries and can be undone', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final vm = container.read(timelineViewModelProvider.notifier);
    vm.appendQueuedMedia(
      items: [
        _mediaItem('one', 'one.jpg'),
        _mediaItem('two', 'two.jpg'),
        _mediaItem('three', 'three.jpg'),
      ],
      imageFits: const {},
      cropTransforms: const {},
    );
    List<MediaTrackClipPayload> clips() => _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    vm.bulkEditStarted(transition: true);
    vm.clipTransitionAppliedToAll(
      type: ClipTransitionType.slide,
      duration: const Duration(milliseconds: 500),
    );
    vm.bulkEditFinished();
    expect(
      clips()
          .take(2)
          .every((clip) => clip.transitionOverride == ClipTransitionType.slide),
      isTrue,
    );
    expect(clips().last.transitionOverride, isNull);
    vm.clipTransitionChanged(
      clipId: clips().first.clipId,
      type: ClipTransitionType.cut,
      duration: const Duration(milliseconds: 300),
    );
    vm.bulkEditUndone();
    expect(clips().first.transitionOverride, ClipTransitionType.cut);
    expect(clips()[1].transitionOverride, isNull);
  });
  test('caption bulk properties and undo remain independent', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final vm = container.read(timelineViewModelProvider.notifier);
    vm.appendQueuedMedia(
      items: [_mediaItem('one', 'one.jpg'), _mediaItem('two', 'two.jpg')],
      imageFits: const {},
      cropTransforms: const {},
    );
    List<MediaTrackClipPayload> clips() => _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    vm.captionChanged(
      clipId: clips().last.clipId,
      caption: 'Individual',
      supportingLine: '',
    );
    vm.captionSettingsChanged(
      clipId: clips().last.clipId,
      settings: const CaptionSettings(
        placement: CaptionPlacement.top,
        startFraction: 0.1,
        sizeScale: 1.3,
      ),
    );
    vm.bulkEditStarted(
      captionText: true,
      captionPosition: true,
      captionTiming: true,
    );
    vm.captionTextAppliedToAll('Shared', 'Subtitle');
    vm.captionPositionAppliedToAll(
      const CaptionSettings(placement: CaptionPlacement.bottom),
    );
    vm.captionTimingAppliedToAll(
      const CaptionSettings(startFraction: 0.25, endFraction: 0.75),
    );
    vm.bulkEditFinished();
    expect(clips().last.caption, 'Shared');
    expect(clips().last.captionSettings.placement, CaptionPlacement.bottom);
    expect(clips().last.captionSettings.sizeScale, 1.3);
    vm.captionChanged(
      clipId: clips().first.clipId,
      caption: 'Later',
      supportingLine: '',
    );
    vm.bulkEditUndone();
    expect(clips().first.caption, 'Later');
    expect(clips().last.caption, 'Individual');
    expect(clips().first.captionSettings.placement, isNull);
    expect(clips().last.captionSettings.placement, CaptionPlacement.top);
    expect(clips().last.captionSettings.startFraction, 0.1);
    expect(clips().last.captionSettings.sizeScale, 1.3);
  });
  test('bulk undo restores framing and caption style without replacing later caption timing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final vm = container.read(timelineViewModelProvider.notifier);
    vm.appendQueuedMedia(
      items: [_mediaItem('one', 'one.jpg'), _mediaItem('two', 'two.jpg')],
      imageFits: const {},
      cropTransforms: const {},
    );
    List<MediaTrackClipPayload> clips() => _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    vm.bulkEditStarted(framing: true, captionStyle: true);
    vm.clipFramingAppliedToAll(
      imageFit: VideoTemplateImageFit.contain,
      crop: ImageCropTransform.centered,
    );
    vm.captionStyleAppliedToAll(const CaptionSettings(sizeScale: 1.2));
    vm.bulkEditFinished();
    final first = clips().first;
    vm.captionSettingsChanged(
      clipId: first.clipId,
      settings: first.captionSettings.copyWith(startFraction: 0.2),
    );
    vm.clipImageFitChanged(
      clipId: first.clipId,
      imageFit: VideoTemplateImageFit.cover,
    );
    vm.bulkEditUndone();
    expect(clips().first.captionSettings.startFraction, 0.2);
    expect(clips().first.captionSettings.sizeScale, 1);
    expect(clips().last.captionSettings.sizeScale, 1);
    expect(clips().last.imageFit, VideoTemplateImageFit.cover);
  });
  test(
    'bulk undo restores the previous project and protects later edits',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      final vm = container.read(timelineViewModelProvider.notifier);
      vm.appendQueuedMedia(
        items: [_mediaItem('one', 'one.jpg'), _mediaItem('two', 'two.jpg')],
        imageFits: const {},
        cropTransforms: const {},
      );
      List<MediaTrackClipPayload> clips() => _trackEvents(
        container.read(timelineViewModelProvider).value!.project,
        'track-media',
      )!.map((e) => e.payload as MediaTrackClipPayload).toList();
      vm.bulkEditStarted(motion: true);
      vm.clipMotionAppliedToAll(preset: ClipMotionPreset.gentlePan);
      vm.bulkEditFinished();
      vm.bulkEditUndone();
      expect(clips().every((clip) => clip.motionOverride == null), isTrue);

      vm.bulkEditStarted(motion: true);
      vm.clipMotionAppliedToAll(preset: ClipMotionPreset.gentlePan);
      vm.bulkEditFinished();
      vm.aspectRatioSelected(VideoTemplateAspectRatio.square);
      vm.clipMotionChanged(
        clipId: clips().first.clipId,
        preset: ClipMotionPreset.slowZoomIn,
      );
      vm.bulkEditUndone();
      expect(
        container
            .read(timelineViewModelProvider)
            .value!
            .project!
            .template
            .aspectRatio,
        VideoTemplateAspectRatio.square,
      );
      expect(clips().first.motionOverride, ClipMotionPreset.slowZoomIn);
      expect(clips().last.motionOverride, isNull);
    },
  );
  test(
    'appending queue preserves edited clips and ignores duplicates',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      final vm = container.read(timelineViewModelProvider.notifier);
      final one = _mediaItem('one', 'one.jpg');
      final two = _mediaItem('two', 'two.jpg');
      expect(
        vm.appendQueuedMedia(
          items: [one],
          imageFits: const {},
          cropTransforms: const {},
        ),
        1,
      );
      final first =
          _trackEvents(
                container.read(timelineViewModelProvider).value!.project,
                'track-media',
              )!.single.payload
              as MediaTrackClipPayload;
      vm.captionChanged(
        clipId: first.clipId,
        caption: 'Edited',
        supportingLine: '',
      );
      expect(
        vm.appendQueuedMedia(
          items: [one, two, two],
          imageFits: const {},
          cropTransforms: const {},
        ),
        1,
      );
      final clips = _trackEvents(
        container.read(timelineViewModelProvider).value!.project,
        'track-media',
      )!.map((event) => event.payload as MediaTrackClipPayload).toList();
      expect(clips.map((clip) => clip.mediaId), ['one', 'two']);
      expect(clips.first.caption, 'Edited');
      expect(clips.last.start, clips.first.end);
    },
  );
  test(
    'style selection preserves aspect ratio and explicit clip choices',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      final vm = container.read(timelineViewModelProvider.notifier);
      const map = BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 1),
      );
      await vm.buildProjectTimeline(
        beatMap: map,
        events: const [],
        selectedMedia: [_mediaItem('one', 'one.jpg')],
      );
      final clip =
          _trackEvents(
                container.read(timelineViewModelProvider).value!.project,
                'track-media',
              )!.single.payload
              as MediaTrackClipPayload;
      vm.captionChanged(
        clipId: clip.clipId,
        caption: 'Memory',
        supportingLine: '',
      );
      vm.clipMotionChanged(
        clipId: clip.clipId,
        preset: ClipMotionPreset.slowZoomOut,
        intensity: ClipMotionIntensity.subtle,
      );
      vm.aspectRatioSelected(VideoTemplateAspectRatio.square);
      vm.templateSelected(VideoTemplates.celebration);
      final project = container.read(timelineViewModelProvider).value!.project!;
      final after =
          _trackEvents(project, 'track-media')!.single.payload
              as MediaTrackClipPayload;
      expect(project.template.aspectRatio, VideoTemplateAspectRatio.square);
      expect(after.caption, 'Memory');
      expect(
        after.motionFor(project.template).preset,
        ClipMotionPreset.slowZoomOut,
      );
      expect(
        after.motionFor(project.template).intensity,
        ClipMotionIntensity.subtle,
      );
    },
  );
  test(
    'repeated photos have independent edits that survive rebuilding',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      final vm = container.read(timelineViewModelProvider.notifier);
      const map = BeatMap(
        beats: [],
        bpm: 120,
        averageBeatInterval: Duration(seconds: 1),
      );
      const markers = [
        BeatEvent(time: Duration.zero, type: 'marker'),
        BeatEvent(time: Duration(seconds: 3), type: 'marker'),
        BeatEvent(time: Duration(seconds: 6), type: 'marker'),
        BeatEvent(time: Duration(seconds: 9), type: 'marker'),
      ];
      final photo = _mediaItem('one', 'one.jpg');
      final other = _mediaItem('two', 'two.jpg');
      await vm.buildProjectTimeline(
        beatMap: map,
        events: markers,
        selectedMedia: [photo, other],
      );
      vm.addManualImagePointAt(
        time: const Duration(seconds: 6),
        beatMap: map,
        selectedMedia: [photo],
        audioDuration: null,
      );
      List<MediaTrackClipPayload> clips() => _trackEvents(
        container.read(timelineViewModelProvider).value!.project,
        'track-media',
      )!.map((event) => event.payload as MediaTrackClipPayload).toList();
      final firstId = clips()[0].clipId;
      final otherId = clips()[1].clipId;
      final repeatedId = clips()[2].clipId;
      expect(firstId, isNotEmpty);
      expect(firstId, isNot(repeatedId));
      vm.captionChanged(
        clipId: repeatedId,
        caption: 'Наше лето',
        supportingLine: '2026',
      );
      vm.captionSettingsChanged(
        clipId: repeatedId,
        settings: const CaptionSettings(
          placement: CaptionPlacement.top,
          entrance: CaptionEntrance.fade,
          startFraction: 0.25,
          endFraction: 0.75,
        ),
      );
      vm.clipImageFitChanged(
        clipId: repeatedId,
        imageFit: VideoTemplateImageFit.contain,
      );
      const crop = ImageCropTransform(focalX: 0.5, focalY: -0.25, zoom: 2);
      vm.clipCropChanged(clipId: repeatedId, transform: crop);
      expect(
        clips().singleWhere((clip) => clip.clipId == firstId).cropTransform,
        ImageCropTransform.centered,
      );
      vm.clipMotionChanged(
        clipId: repeatedId,
        preset: ClipMotionPreset.gentlePan,
        intensity: ClipMotionIntensity.moreMovement,
      );
      expect(clips()[0].caption, isEmpty);
      vm.syncSelectedMediaToMarkers(selectedMedia: [other, photo]);
      expect(clips().map((clip) => clip.mediaId), ['one', 'two', 'one']);
      await vm.buildProjectTimeline(
        beatMap: map,
        events: markers,
        selectedMedia: [other, photo],
      );
      expect(clips().map((clip) => clip.mediaId), ['two', 'one', 'one']);
      expect(clips().map((clip) => clip.clipId), [
        otherId,
        firstId,
        repeatedId,
      ]);
      final retained = clips().singleWhere((clip) => clip.clipId == repeatedId);
      expect(retained.caption, 'Наше лето');
      expect(retained.captionSupportingLine, '2026');
      expect(retained.captionSettings.placement, CaptionPlacement.top);
      expect(retained.captionSettings.entrance, CaptionEntrance.fade);
      expect(retained.captionSettings.startFraction, 0.25);
      expect(retained.imageFit, VideoTemplateImageFit.contain);
      expect(retained.cropTransform, crop);
      final serializer = const ProjectSerializer();
      final reopened = serializer.deserialize(
        serializer.serialize(
          container.read(timelineViewModelProvider).value!.project!,
        ),
      );
      final reopenedClips = _trackEvents(
        reopened,
        'track-media',
      )!.map((event) => event.payload as MediaTrackClipPayload);
      expect(
        reopenedClips
            .singleWhere((clip) => clip.clipId == repeatedId)
            .cropTransform,
        crop,
      );
      expect(
        reopenedClips
            .singleWhere((clip) => clip.clipId == firstId)
            .cropTransform,
        ImageCropTransform.centered,
      );
      expect(retained.motionOverride, ClipMotionPreset.gentlePan);
      expect(retained.motionIntensity, ClipMotionIntensity.moreMovement);
      expect(
        clips().singleWhere((clip) => clip.clipId == firstId).cropTransform,
        ImageCropTransform.centered,
      );
      expect(
        clips().singleWhere((clip) => clip.clipId == firstId).caption,
        isEmpty,
      );
      vm.captionStyleAppliedToAll(
        const CaptionSettings(
          preset: CaptionStylePreset.bold,
          sizeScale: 1.2,
          backdrop: CaptionBackdrop.strongPanel,
        ),
      );
      final styledClips = clips();
      expect(styledClips.map((clip) => clip.clipId), [
        otherId,
        firstId,
        repeatedId,
      ]);
      expect(styledClips[0].caption, isEmpty);
      expect(styledClips[2].caption, 'Наше лето');
      expect(styledClips[2].captionSettings.placement, CaptionPlacement.top);
      expect(styledClips[2].captionSettings.startFraction, 0.25);
      expect(
        styledClips[2].captionSettings.backdrop,
        CaptionBackdrop.strongPanel,
      );
    },
  );
  test('applying markers preserves the reordered timeline photos', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final vm = container.read(timelineViewModelProvider.notifier);
    const map = BeatMap(beats: [], bpm: 0, averageBeatInterval: Duration.zero);
    const markers = [
      BeatEvent(time: Duration.zero, type: 'marker'),
      BeatEvent(time: Duration(seconds: 3), type: 'marker'),
    ];
    final first = _mediaItem('one', 'one.jpg');
    final second = _mediaItem('two', 'two.jpg');
    for (final marker in markers) {
      vm.addImageMarkerAt(
        time: marker.time,
        beatMap: map,
        fallbackMarkerEvents: const [],
      );
    }
    await vm.buildProjectTimeline(
      beatMap: map,
      events: markers,
      selectedMedia: [first, second],
    );

    final originalClips = _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    expect(vm.clipMoved(clipId: originalClips[1].clipId, position: 1), isTrue);
    expect(vm.applyMarkersToImages(selectedMedia: [first, second]), 2);
    final clips = _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    expect(clips.map((clip) => clip.mediaId), ['two', 'one']);
    expect(clips.map((clip) => clip.clipId), [
      originalClips[1].clipId,
      originalClips[0].clipId,
    ]);
    expect(clips.map((clip) => clip.start), [
      Duration.zero,
      const Duration(seconds: 3),
    ]);
    expect(vm.undoMarkerEdit(), isTrue);
  });
  test('applying fewer markers retains later photos in order', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final vm = container.read(timelineViewModelProvider.notifier);
    const map = BeatMap(beats: [], bpm: 0, averageBeatInterval: Duration.zero);
    final photos = [
      _mediaItem('one', 'one.jpg'),
      _mediaItem('two', 'two.jpg'),
      _mediaItem('three', 'three.jpg'),
    ];
    for (final seconds in [0, 3, 6]) {
      vm.addImageMarkerAt(
        time: Duration(seconds: seconds),
        beatMap: map,
        fallbackMarkerEvents: const [],
      );
    }
    await vm.buildProjectTimeline(
      beatMap: map,
      events: const [
        BeatEvent(time: Duration.zero, type: 'marker'),
        BeatEvent(time: Duration(seconds: 3), type: 'marker'),
        BeatEvent(time: Duration(seconds: 6), type: 'marker'),
      ],
      selectedMedia: photos,
    );
    vm.deleteImageMarkerAt(const Duration(seconds: 6));
    expect(vm.applyMarkersToImages(selectedMedia: photos), 2);
    final clips = _trackEvents(
      container.read(timelineViewModelProvider).value!.project,
      'track-media',
    )!.map((event) => event.payload as MediaTrackClipPayload).toList();
    expect(clips.map((clip) => clip.mediaId), ['one', 'two', 'three']);
    expect(clips[2].start, greaterThanOrEqualTo(clips[1].end));
  });
  test(
    'buildProjectTimeline creates a project with serialized payload',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(timelineViewModelProvider.future);
      container
          .read(timelineViewModelProvider.notifier)
          .templateSelected(VideoTemplates.fastSocialReel);
      await container
          .read(timelineViewModelProvider.notifier)
          .buildProjectTimeline(
            beatMap: const BeatMap(
              beats: [Beat(time: Duration(milliseconds: 200), strength: 1.5)],
              bpm: 120,
              averageBeatInterval: Duration(milliseconds: 500),
            ),
            events: const [
              BeatEvent(
                time: Duration(milliseconds: 200),
                type: 'marker',
                payload: 'Beat 1',
              ),
            ],
          );

      final state = container.read(timelineViewModelProvider);

      expect(state, isA<AsyncData<TimelineState>>());
      expect(state.value?.hasProject, isTrue);
      expect(state.value?.project?.tracks.length, 1);
      expect(
        state.value?.serializedProject?['name'],
        'Picture To Videos Project',
      );
      expect(
        state.value?.project?.template.id,
        VideoTemplates.fastSocialReel.id,
      );
    },
  );

  test('saveMarkerPreset stores marker track for the current audio', () async {
    final repository = _MemoryAudioMarkerPresetRepository();
    final container = ProviderContainer(
      overrides: [
        audioMarkerPresetRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    const audioData = AudioData(
      samples: [0.1, 0.2, 0.3],
      sampleRate: 44100,
      duration: Duration(seconds: 2),
      channelCount: 1,
    );

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [Beat(time: Duration(milliseconds: 500), strength: 1)],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 500),
              type: 'marker',
              payload: 'Marker 1',
            ),
          ],
        );
    final savedCount = await container
        .read(timelineViewModelProvider.notifier)
        .saveMarkerPreset(
          audioData: audioData,
          sourceName: 'song.wav',
          sourcePath: '/tmp/song.wav',
          sourceExtension: 'wav',
          byteLength: 4096,
        );

    final savedPreset = await repository.load(
      audioSignature: const AudioCacheSignatureBuilder().build(audioData),
    );

    expect(savedCount, 1);
    expect(savedPreset?.sourceName, 'song.wav');
    expect(savedPreset?.sourcePath, '/tmp/song.wav');
    expect(savedPreset?.sourceExtension, 'wav');
    expect(savedPreset?.byteLength, 4096);
    expect(savedPreset?.duration, const Duration(seconds: 2));
    expect(savedPreset?.markers.single.time, const Duration(milliseconds: 500));
  });

  test('aspectRatioSelected updates current template and project', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [Beat(time: Duration(milliseconds: 500), strength: 1)],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 500),
              type: 'marker',
              payload: 'Marker 1',
            ),
          ],
        );

    container
        .read(timelineViewModelProvider.notifier)
        .aspectRatioSelected(VideoTemplateAspectRatio.square);

    final state = container.read(timelineViewModelProvider).value;

    expect(
      state?.selectedTemplate.aspectRatio,
      VideoTemplateAspectRatio.square,
    );
    expect(
      state?.project?.template.aspectRatio,
      VideoTemplateAspectRatio.square,
    );
    expect(
      (state?.serializedProject?['template']
          as Map<String, Object?>?)?['aspectRatio'],
      '1:1',
    );
  });

  test('timelineScaleChanged stores clamped timeline scale', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);

    container.read(timelineViewModelProvider.notifier).timelineScaleChanged(2);
    expect(container.read(timelineViewModelProvider).value?.timelineScale, 2);

    container.read(timelineViewModelProvider.notifier).timelineScaleChanged(10);
    expect(container.read(timelineViewModelProvider).value?.timelineScale, 3);
  });

  test('deleteImageMarkerAt preserves the media sequence', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [
              Beat(time: Duration(milliseconds: 500), strength: 1),
              Beat(time: Duration(milliseconds: 1000), strength: 1),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 500),
              type: 'marker',
              payload: 'Marker 1',
            ),
            BeatEvent(
              time: Duration(milliseconds: 1000),
              type: 'marker',
              payload: 'Marker 2',
            ),
          ],
          selectedMedia: [_mediaItem('img-1', 'one.jpg')],
        );

    container
        .read(timelineViewModelProvider.notifier)
        .deleteImageMarkerAt(const Duration(milliseconds: 1100));

    final project = container.read(timelineViewModelProvider).value?.project;
    expect(_trackEvents(project, 'track-markers')?.map((event) => event.time), [
      const Duration(milliseconds: 500),
    ]);
    expect(_trackEvents(project, 'track-media')?.map((event) => event.time), [
      Duration.zero,
    ]);
  });

  test('clearImageMarkers preserves the media sequence', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [
              Beat(time: Duration(milliseconds: 500), strength: 1),
              Beat(time: Duration(milliseconds: 1000), strength: 1),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 500),
              type: 'marker',
              payload: 'Marker 1',
            ),
            BeatEvent(
              time: Duration(milliseconds: 1000),
              type: 'marker',
              payload: 'Marker 2',
            ),
          ],
          selectedMedia: [_mediaItem('img-1', 'one.jpg')],
        );

    container.read(timelineViewModelProvider.notifier).clearImageMarkers();

    final state = container.read(timelineViewModelProvider).value;
    expect(_trackEvents(state?.project, 'track-markers'), isEmpty);
    expect(_trackEvents(state?.project, 'track-media'), hasLength(1));
    expect(state?.selectedMarker, isNull);
    expect(state?.nextQueuedMediaIndex, 0);
  });

  test('staging images syncs them to the current marker timeline', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: const BeatMap(
            beats: [
              Beat(time: Duration(milliseconds: 500), strength: 1),
              Beat(time: Duration(milliseconds: 1000), strength: 1),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          events: const [
            BeatEvent(
              time: Duration(milliseconds: 500),
              type: 'marker',
              payload: 'Marker 1',
            ),
            BeatEvent(
              time: Duration(milliseconds: 1000),
              type: 'marker',
              payload: 'Marker 2',
            ),
          ],
        );

    container.read(editorMediaSelectionViewModelProvider.notifier).addAllMedia([
      _mediaItem('img-1', 'one.jpg'),
      _mediaItem('img-2', 'two.jpg'),
    ]);

    final project = container.read(timelineViewModelProvider).value?.project;
    final mediaTrack = project?.tracks.firstWhere(
      (track) => track.id == 'track-media',
    );
    final payloads = mediaTrack?.events
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();

    expect(payloads?.map((payload) => payload.mediaId), ['img-1', 'img-2']);
    expect(payloads?.map((payload) => payload.start), [
      Duration.zero,
      const Duration(milliseconds: 3500),
    ]);
  });
}

List<BeatEvent>? _trackEvents(ProjectTimeline? project, String id) {
  return project?.tracks.where((track) => track.id == id).firstOrNull?.events;
}

LibraryMediaItem _mediaItem(String id, String title) {
  return LibraryMediaItem(
    id: id,
    title: title,
    sizeLabel: '1 MB',
    tagline: 'Ready',
    importedOnLabel: 'Jun 09, 2026',
    importedOn: DateTime(2026, 6, 9),
    byteLength: 1000000,
    thumbnailBytes: Uint8List(0),
    sourcePath: '/tmp/$title',
  );
}

class _MemoryAudioMarkerPresetRepository
    implements AudioMarkerPresetRepository {
  AudioMarkerPreset? _entry;

  @override
  Future<void> clear() async {
    _entry = null;
  }

  @override
  Future<AudioMarkerPreset?> load({required String audioSignature}) async {
    if (_entry?.audioSignature != audioSignature) {
      return null;
    }

    return _entry;
  }

  @override
  Future<List<AudioMarkerPreset>> loadAll() async {
    return _entry == null ? const [] : [_entry!];
  }

  @override
  Future<void> save(AudioMarkerPreset preset) async {
    _entry = preset;
  }
}
