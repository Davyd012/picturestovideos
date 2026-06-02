import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';

final frameEnergyAnalyzerProvider = Provider<FrameEnergyAnalyzer>(
  (ref) => const FrameEnergyAnalyzer(),
);

class FrameEnergyAnalyzer {
  const FrameEnergyAnalyzer();

  List<AudioFrame> analyze({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) {
    if (audioData.sampleRate <= 0) {
      throw ArgumentError.value(
        audioData.sampleRate,
        'audioData.sampleRate',
        'Sample rate must be greater than zero.',
      );
    }

    if (config.frameSize <= 0) {
      throw ArgumentError.value(
        config.frameSize,
        'config.frameSize',
        'Frame size must be greater than zero.',
      );
    }

    if (config.hopSize <= 0) {
      throw ArgumentError.value(
        config.hopSize,
        'config.hopSize',
        'Hop size must be greater than zero.',
      );
    }

    final samples = audioData.samples;
    if (samples.isEmpty) {
      return const [];
    }

    final frames = <AudioFrame>[];
    for (var start = 0; start < samples.length; start += config.hopSize) {
      final end = min(start + config.frameSize, samples.length);
      var sumSquares = 0.0;

      for (var index = start; index < end; index++) {
        final sample = samples[index];
        sumSquares += sample * sample;
      }

      final sampleCount = end - start;
      final energy =
          sampleCount == 0 ? 0.0 : sqrt(sumSquares / sampleCount);

      frames.add(
        AudioFrame(
          time: Duration(
            microseconds:
                (start * Duration.microsecondsPerSecond) ~/ audioData.sampleRate,
          ),
          energy: energy,
        ),
      );
    }

    if (!config.normalizeEnergies) {
      return List.unmodifiable(frames);
    }

    final maxEnergy = frames.fold<double>(
      0,
      (currentMax, frame) => max(currentMax, frame.energy),
    );
    if (maxEnergy == 0) {
      return List.unmodifiable(frames);
    }

    return List.unmodifiable([
      for (final frame in frames)
        AudioFrame(
          time: frame.time,
          energy: frame.energy / maxEnergy,
        ),
    ]);
  }
}
