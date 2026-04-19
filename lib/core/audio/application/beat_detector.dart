import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';

final beatDetectorProvider = Provider<BeatDetector>(
  (ref) => const BeatDetector(),
);

class BeatDetector {
  const BeatDetector();

  List<Beat> detect({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) {
    if (config.sensitivity <= 0) {
      throw ArgumentError.value(
        config.sensitivity,
        'config.sensitivity',
        'Sensitivity must be greater than zero.',
      );
    }

    if (config.movingAverageWindow <= 0) {
      throw ArgumentError.value(
        config.movingAverageWindow,
        'config.movingAverageWindow',
        'Moving average window must be greater than zero.',
      );
    }

    if (frames.length < 2) {
      return const [];
    }

    final beats = <Beat>[];
    Duration? lastBeatTime;

    for (var index = 0; index < frames.length; index++) {
      final frame = frames[index];
      final previousEnergy = index == 0 ? 0.0 : frames[index - 1].energy;
      final averageEnergy = _averageEnergy(
        frames: frames,
        endIndexInclusive: index,
        window: config.movingAverageWindow,
      );
      final threshold = averageEnergy * config.sensitivity;

      final isLocalPeak = frame.energy > previousEnergy &&
          (index == frames.length - 1 ||
              frame.energy >= frames[index + 1].energy);
      final clearsThreshold = frame.energy > threshold;
      final respectsDebounce = lastBeatTime == null ||
          frame.time - lastBeatTime >= config.minBeatInterval;

      if (!isLocalPeak || !clearsThreshold || !respectsDebounce) {
        continue;
      }

      lastBeatTime = frame.time;
      final strength =
          averageEnergy == 0 ? frame.energy : frame.energy / averageEnergy;
      beats.add(
        Beat(
          time: frame.time,
          strength: strength,
        ),
      );
    }

    return List.unmodifiable(beats);
  }

  double _averageEnergy({
    required List<AudioFrame> frames,
    required int endIndexInclusive,
    required int window,
  }) {
    final startIndex =
        (endIndexInclusive - window + 1).clamp(0, endIndexInclusive) as int;
    var sum = 0.0;

    for (var index = startIndex; index <= endIndexInclusive; index++) {
      sum += frames[index].energy;
    }

    return sum / (endIndexInclusive - startIndex + 1);
  }
}
