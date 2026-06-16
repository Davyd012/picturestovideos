import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/application/preprocess_audio_use_case.dart';
import 'package:picturestovideos/core/audio/data/beat_map_cache_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/beat_map_cache_entry.dart';
import 'package:picturestovideos/features/preprocessing/preprocessing_state.dart';
import 'package:picturestovideos/features/preprocessing/preprocessing_view_model.dart';

void main() {
  test('saveBeatMap then loadCachedBeatMap returns cache hit', () async {
    final repository = _MemoryBeatMapCacheRepository();
    final container = ProviderContainer(
      overrides: [
        preprocessAudioUseCaseProvider.overrideWithValue(
          PreprocessAudioUseCase(
            cacheRepository: repository,
            signatureBuilder: const AudioCacheSignatureBuilder(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    const audioData = AudioData(
      samples: [0.1, 0.2, 0.3],
      sampleRate: 44100,
      duration: Duration(milliseconds: 900),
      channelCount: 1,
    );
    const beatMap = BeatMap(
      beats: [Beat(time: Duration(milliseconds: 500), strength: 1.5)],
      bpm: 120,
      averageBeatInterval: Duration(milliseconds: 500),
    );

    await container.read(preprocessingViewModelProvider.future);
    await container
        .read(preprocessingViewModelProvider.notifier)
        .saveBeatMap(audioData: audioData, beatMap: beatMap);
    await container
        .read(preprocessingViewModelProvider.notifier)
        .loadCachedBeatMap(audioData);

    final state = container.read(preprocessingViewModelProvider);

    expect(state, isA<AsyncData<PreprocessingState>>());
    expect(state.value?.hasCachedBeatMap, isTrue);
    expect(state.value?.lastAction, 'Cache hit');
    expect(state.value?.cachedBeatMap?.bpm, 120);
  });
}

class _MemoryBeatMapCacheRepository implements BeatMapCacheRepository {
  BeatMapCacheEntry? _entry;

  @override
  Future<void> clear() async {
    _entry = null;
  }

  @override
  Future<BeatMapCacheEntry?> load({required String audioSignature}) async {
    if (_entry?.audioSignature != audioSignature) {
      return null;
    }

    return _entry;
  }

  @override
  Future<void> save(BeatMapCacheEntry entry) async {
    _entry = entry;
  }
}
