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
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
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

  test('deleteImageMarkerAt removes nearest marker and media clip', () async {
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
      const Duration(milliseconds: 500),
    ]);
  });

  test('clearImageMarkers removes all marker and media events', () async {
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
    expect(_trackEvents(state?.project, 'track-media'), isEmpty);
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
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 1000),
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
