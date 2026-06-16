import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/analyze_audio_frames_use_case.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/application/decode_wav_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/detect_beats_use_case.dart';
import 'package:picturestovideos/core/audio/application/frame_energy_analyzer.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/prepare_audio_for_analysis_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/audio/domain/audio_processing_task.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test('pickAudioFile completes the import pipeline', () async {
    final container = ProviderContainer(overrides: _audioImportOverrides());
    addTearDown(container.dispose);
    final subscription = container.listen(
      audioImportViewModelProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(audioImportViewModelProvider.future);
    await container.read(audioImportViewModelProvider.notifier).pickAudioFile();

    final state = container.read(audioImportViewModelProvider);

    expect(state, isA<AsyncData<AudioImportState>>());
    expect(state.value?.source?.fileName, 'beat.wav');
    expect(state.value?.audioData?.sampleRate, 44100);
    expect(state.value?.flowState, AudioImportFlowState.completed);
    expect(state.value?.canOpenEditor, isTrue);
  });

  test('stopImport resets the import state', () async {
    final container = ProviderContainer(overrides: _audioImportOverrides());
    addTearDown(container.dispose);

    await container.read(audioImportViewModelProvider.future);
    await container.read(audioImportViewModelProvider.notifier).pickAudioFile();
    await container.read(audioImportViewModelProvider.notifier).stopImport();

    final state = container.read(audioImportViewModelProvider).value;

    expect(state?.flowState, AudioImportFlowState.empty);
    expect(state?.source, isNull);
  });

  test('pickAudioFile applies saved marker preset', () async {
    const audioData = AudioData(
      samples: [0.0, 0.8, -0.4, 0.6, -0.2, 0.3],
      sampleRate: 44100,
      duration: Duration(seconds: 2),
      channelCount: 1,
    );
    final repository = _MemoryAudioMarkerPresetRepository(
      entry: AudioMarkerPreset(
        version: 1,
        audioSignature: const AudioCacheSignatureBuilder().build(audioData),
        sourceName: 'beat.wav',
        sourcePath: '/tmp/beat.wav',
        sourceExtension: 'wav',
        byteLength: 128,
        duration: const Duration(seconds: 2),
        updatedAt: DateTime(2026, 6, 9),
        markers: const [
          BeatEvent(
            time: Duration(milliseconds: 300),
            type: 'marker',
            payload: 'Marker 1',
          ),
          BeatEvent(
            time: Duration(milliseconds: 900),
            type: 'marker',
            payload: 'Marker 2',
          ),
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: _audioImportOverrides(
        audioData: audioData,
        markerPresetRepository: repository,
      ),
    );
    addTearDown(container.dispose);

    container.read(editorMediaSelectionViewModelProvider.notifier).addAllMedia([
      _mediaItem('img-1', 'one.jpg'),
      _mediaItem('img-2', 'two.jpg'),
    ]);
    await container.read(audioImportViewModelProvider.future);
    await container.read(audioImportViewModelProvider.notifier).pickAudioFile();

    final timeline = container.read(timelineViewModelProvider).value;
    final playback = container.read(playbackViewModelProvider).value;
    final markerTrack = timeline?.project?.tracks.firstWhere(
      (track) => track.id == 'track-markers',
    );
    final mediaTrack = timeline?.project?.tracks.firstWhere(
      (track) => track.id == 'track-media',
    );
    final mediaPayloads = mediaTrack?.events
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();

    expect(markerTrack?.events.map((event) => event.time), [
      const Duration(milliseconds: 300),
      const Duration(milliseconds: 900),
    ]);
    expect(mediaPayloads?.map((payload) => payload.mediaId), [
      'img-1',
      'img-2',
    ]);
    expect(playback?.beatMap.beats.length, 2);
  });

  test(
    'pickAudioFile applies saved markers with different selected images',
    () async {
      const audioData = AudioData(
        samples: [0.0, 0.8, -0.4, 0.6, -0.2, 0.3],
        sampleRate: 44100,
        duration: Duration(seconds: 2),
        channelCount: 1,
      );
      final repository = _MemoryAudioMarkerPresetRepository(
        entry: AudioMarkerPreset(
          version: 1,
          audioSignature: const AudioCacheSignatureBuilder().build(audioData),
          sourceName: 'beat.wav',
          sourcePath: '/tmp/beat.wav',
          sourceExtension: 'wav',
          byteLength: 128,
          duration: const Duration(seconds: 2),
          updatedAt: DateTime(2026, 6, 9),
          markers: const [
            BeatEvent(
              time: Duration(milliseconds: 300),
              type: 'marker',
              payload: 'Marker 1',
            ),
            BeatEvent(
              time: Duration(milliseconds: 900),
              type: 'marker',
              payload: 'Marker 2',
            ),
          ],
        ),
      );
      final container = ProviderContainer(
        overrides: _audioImportOverrides(
          audioData: audioData,
          markerPresetRepository: repository,
        ),
      );
      addTearDown(container.dispose);

      container
          .read(editorMediaSelectionViewModelProvider.notifier)
          .addAllMedia([
            _mediaItem('img-3', 'three.jpg'),
            _mediaItem('img-4', 'four.jpg'),
          ]);
      await container.read(audioImportViewModelProvider.future);
      await container
          .read(audioImportViewModelProvider.notifier)
          .pickAudioFile();

      final mediaTrack = container
          .read(timelineViewModelProvider)
          .value
          ?.project
          ?.tracks
          .firstWhere((track) => track.id == 'track-media');
      final mediaPayloads = mediaTrack?.events
          .map((event) => event.payload)
          .whereType<MediaTrackClipPayload>()
          .toList();

      expect(mediaPayloads?.map((payload) => payload.mediaId), [
        'img-3',
        'img-4',
      ]);
      expect(mediaPayloads?.map((payload) => payload.start), [
        const Duration(milliseconds: 300),
        const Duration(milliseconds: 900),
      ]);
    },
  );
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

dynamic _audioImportOverrides({
  AudioData? audioData,
  AudioMarkerPresetRepository? markerPresetRepository,
}) {
  final resolvedAudioData =
      audioData ??
      const AudioData(
        samples: [0.0, 0.8, -0.4, 0.6, -0.2, 0.3],
        sampleRate: 44100,
        duration: Duration(seconds: 2),
        channelCount: 1,
      );
  final frames = const [
    AudioFrame(time: Duration.zero, energy: 0.2),
    AudioFrame(time: Duration(milliseconds: 500), energy: 0.9),
    AudioFrame(time: Duration(seconds: 1), energy: 0.2),
  ];
  final beats = const [
    Beat(time: Duration.zero, strength: 1),
    Beat(time: Duration(milliseconds: 500), strength: 1),
    Beat(time: Duration(seconds: 1), strength: 1),
  ];

  return [
    importAudioUseCaseProvider.overrideWithValue(
      _FakeImportAudioUseCase(result: _selectedAudioFile()),
    ),
    prepareAudioForAnalysisUseCaseProvider.overrideWithValue(
      _FakePrepareAudioForAnalysisUseCase(),
    ),
    decodeWavAudioUseCaseProvider.overrideWithValue(
      _FakeDecodeWavAudioUseCase(audioData: resolvedAudioData),
    ),
    analyzeAudioFramesUseCaseProvider.overrideWithValue(
      _FakeAnalyzeAudioFramesUseCase(frames: frames),
    ),
    detectBeatsUseCaseProvider.overrideWithValue(
      _FakeDetectBeatsUseCase(beats: beats),
    ),
    audioPlayerRepositoryProvider.overrideWithValue(
      ManualAudioPlayerRepository(),
    ),
    audioMarkerPresetRepositoryProvider.overrideWithValue(
      markerPresetRepository ?? _MemoryAudioMarkerPresetRepository(),
    ),
  ];
}

SelectedAudioFile _selectedAudioFile() {
  return SelectedAudioFile(
    source: const AudioSource(
      fileName: 'beat.wav',
      fileExtension: 'wav',
      byteLength: 128,
      path: '/tmp/beat.wav',
    ),
    bytes: Uint8List.fromList(const [
      82,
      73,
      70,
      70,
      0,
      0,
      0,
      0,
      87,
      65,
      86,
      69,
    ]),
  );
}

class _FakeImportAudioUseCase extends ImportAudioUseCase {
  _FakeImportAudioUseCase({required this.result})
    : super(audioRepository: _NoopAudioRepository());

  final SelectedAudioFile? result;

  @override
  Future<SelectedAudioFile?> call() async {
    return result;
  }
}

class _FakePrepareAudioForAnalysisUseCase
    extends PrepareAudioForAnalysisUseCase {
  _FakePrepareAudioForAnalysisUseCase() : super(logger: AppLogger(appTalker));

  @override
  Future<SelectedAudioFile> call(SelectedAudioFile selectedFile) async {
    return selectedFile;
  }
}

class _FakeDecodeWavAudioUseCase extends DecodeWavAudioUseCase {
  const _FakeDecodeWavAudioUseCase({required this.audioData});

  final AudioData audioData;

  @override
  Future<AudioData> call({required DecodeWavAudioRequest request}) async {
    return audioData;
  }
}

class _FakeAnalyzeAudioFramesUseCase extends AnalyzeAudioFramesUseCase {
  _FakeAnalyzeAudioFramesUseCase({required this.frames})
    : super(frameEnergyAnalyzer: const _NoopFrameEnergyAnalyzer());

  final List<AudioFrame> frames;

  @override
  Future<List<AudioFrame>> call({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) async {
    return frames;
  }
}

class _FakeDetectBeatsUseCase extends DetectBeatsUseCase {
  _FakeDetectBeatsUseCase({required this.beats})
    : super(beatDetector: const _NoopBeatDetector());

  final List<Beat> beats;

  @override
  Future<List<Beat>> call({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) async {
    return beats;
  }
}

class _NoopFrameEnergyAnalyzer extends FrameEnergyAnalyzer {
  const _NoopFrameEnergyAnalyzer();

  @override
  List<AudioFrame> analyze({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) {
    return const [];
  }
}

class _NoopBeatDetector extends BeatDetector {
  const _NoopBeatDetector();

  @override
  List<Beat> detect({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) {
    return const [];
  }
}

class _NoopAudioRepository implements AudioRepository {
  @override
  Future<SelectedAudioFile?> importAudio() async {
    return null;
  }

  @override
  Future<SelectedAudioFile> importAudioFromPath(String path) async {
    return _selectedAudioFile();
  }
}

class _MemoryAudioMarkerPresetRepository
    implements AudioMarkerPresetRepository {
  _MemoryAudioMarkerPresetRepository({AudioMarkerPreset? entry}) {
    _entry = entry;
  }

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
