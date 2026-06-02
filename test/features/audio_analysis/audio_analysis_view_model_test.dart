import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/analyze_audio_frames_use_case.dart';
import 'package:picturestovideos/core/audio/application/frame_energy_analyzer.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_state.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';

void main() {
  test('analyzeAudio stores generated frames', () async {
    final container = ProviderContainer(
      overrides: [
        analyzeAudioFramesUseCaseProvider.overrideWithValue(
          _FakeAnalyzeAudioFramesUseCase(
            frames: const [
              AudioFrame(time: Duration.zero, energy: 0.2),
              AudioFrame(time: Duration(milliseconds: 250), energy: 0.8),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(audioAnalysisViewModelProvider.future);
    await container
        .read(audioAnalysisViewModelProvider.notifier)
        .analyzeAudio(
          const AudioData(
            samples: [0.1, 0.2],
            sampleRate: 4,
            duration: Duration(milliseconds: 500),
            channelCount: 1,
          ),
        );

    final state = container.read(audioAnalysisViewModelProvider);

    expect(state, isA<AsyncData<AudioAnalysisState>>());
    expect(state.value?.frameCount, 2);
    expect(state.value?.peakEnergy, 0.8);
  });
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
