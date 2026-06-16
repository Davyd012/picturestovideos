import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';

class AudioAnalysisState {
  const AudioAnalysisState({required this.config, required this.frames});

  const AudioAnalysisState.initial()
    : config = const AudioAnalysisConfig.defaults(),
      frames = const [];

  final AudioAnalysisConfig config;
  final List<AudioFrame> frames;

  int get frameCount => frames.length;

  double get peakEnergy => frames.fold<double>(
    0,
    (currentMax, frame) =>
        frame.energy > currentMax ? frame.energy : currentMax,
  );

  AudioFrame? get firstFrame => frames.isEmpty ? null : frames.first;

  AudioFrame? get lastFrame => frames.isEmpty ? null : frames.last;
}
