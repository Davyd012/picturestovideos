import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/frame_energy_analyzer.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';

final analyzeAudioFramesUseCaseProvider = Provider<AnalyzeAudioFramesUseCase>(
  (ref) => AnalyzeAudioFramesUseCase(
    frameEnergyAnalyzer: ref.watch(frameEnergyAnalyzerProvider),
  ),
);

class AnalyzeAudioFramesUseCase {
  const AnalyzeAudioFramesUseCase({
    required FrameEnergyAnalyzer frameEnergyAnalyzer,
  }) : this._(frameEnergyAnalyzer);

  const AnalyzeAudioFramesUseCase._(this._frameEnergyAnalyzer);

  final FrameEnergyAnalyzer _frameEnergyAnalyzer;

  List<AudioFrame> call({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) {
    return _frameEnergyAnalyzer.analyze(
      audioData: audioData,
      config: config,
    );
  }
}
