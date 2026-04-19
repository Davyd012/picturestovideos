import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';

final beatMapBuilderProvider = Provider<BeatMapBuilder>(
  (ref) => const BeatMapBuilder(),
);

class BeatMapBuilder {
  const BeatMapBuilder();

  BeatMap build({
    required List<Beat> beats,
  }) {
    if (beats.isEmpty) {
      return const BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration.zero,
      );
    }

    if (beats.length == 1) {
      return BeatMap(
        beats: List.unmodifiable(beats),
        bpm: 0,
        averageBeatInterval: Duration.zero,
      );
    }

    final intervals = <Duration>[];
    for (var index = 1; index < beats.length; index++) {
      intervals.add(beats[index].time - beats[index - 1].time);
    }

    final averageIntervalMicros = intervals
            .map((interval) => interval.inMicroseconds)
            .reduce((sum, value) => sum + value) ~/
        intervals.length;
    final averageInterval = Duration(microseconds: averageIntervalMicros);
    final bpm =
        averageIntervalMicros == 0 ? 0.0 : 60000000 / averageIntervalMicros;

    return BeatMap(
      beats: List.unmodifiable(beats),
      bpm: bpm,
      averageBeatInterval: averageInterval,
    );
  }
}
