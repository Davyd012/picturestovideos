import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/analyze_audio_frames_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_state.dart';

final audioAnalysisViewModelProvider = AsyncNotifierProvider.autoDispose<
    AudioAnalysisViewModel, AudioAnalysisState>(
  AudioAnalysisViewModel.new,
);

class AudioAnalysisViewModel extends AsyncNotifier<AudioAnalysisState> {
  @override
  Future<AudioAnalysisState> build() async {
    return const AudioAnalysisState.initial();
  }

  Future<void> analyzeAudio(
    AudioData audioData, {
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final frames = ref.read(analyzeAudioFramesUseCaseProvider).call(
            audioData: audioData,
            config: config,
          );

      return AudioAnalysisState(
        config: config,
        frames: frames,
      );
    });
  }
}
