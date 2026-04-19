import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/preprocess_audio_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/features/preprocessing/preprocessing_state.dart';

final preprocessingViewModelProvider =
    AsyncNotifierProvider.autoDispose<PreprocessingViewModel, PreprocessingState>(
  PreprocessingViewModel.new,
);

class PreprocessingViewModel extends AsyncNotifier<PreprocessingState> {
  @override
  Future<PreprocessingState> build() async {
    return const PreprocessingState.initial();
  }

  Future<void> loadCachedBeatMap(AudioData audioData) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final cachedBeatMap =
          await ref.read(preprocessAudioUseCaseProvider).loadCachedBeatMap(audioData);

      return PreprocessingState(
        cachedBeatMap: cachedBeatMap,
        lastAction: cachedBeatMap == null ? 'Cache miss' : 'Cache hit',
      );
    });
  }

  Future<void> saveBeatMap({
    required AudioData audioData,
    required BeatMap beatMap,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(preprocessAudioUseCaseProvider).saveBeatMap(
            audioData: audioData,
            beatMap: beatMap,
          );

      return PreprocessingState(
        cachedBeatMap: beatMap,
        lastAction: 'Saved beat map cache',
      );
    });
  }
}
