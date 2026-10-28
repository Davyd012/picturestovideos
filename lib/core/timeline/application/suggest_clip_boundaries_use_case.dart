import 'dart:math' as math;

import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';

/// Uses each photo once, starts at music time zero, and ends at the shorter of
/// the music or the suggested sequence length. Markers are optional candidates.
class SuggestClipBoundariesUseCase {
  const SuggestClipBoundariesUseCase();

  List<Duration> call({
    required int photoCount,
    required BeatMap beatMap,
    required List<BeatEvent> markers,
    required SequencePacing pacing,
    Duration? audioDuration,
  }) {
    if (photoCount <= 0) return const [];
    final targetEnd = pacing.targetDuration * photoCount;
    final end =
        audioDuration != null &&
            audioDuration > Duration.zero &&
            audioDuration < targetEnd
        ? audioDuration
        : targetEnd;
    final total = end.inMicroseconds;
    final step = total / photoCount;
    final minimum = math.max(1, (step * 0.45).floor());
    final times =
        markers
            .map((m) => m.time.inMicroseconds)
            .where((t) => t > 0 && t < total)
            .toSet()
            .toList()
          ..sort();
    final strengths = {
      for (final beat in beatMap.beats) beat.time.inMicroseconds: beat.strength,
    };
    final maxStrength = strengths.values.fold<double>(
      0,
      (value, strength) => math.max(value, strength),
    );
    final result = <Duration>[Duration.zero];
    var previous = 0;
    for (var i = 1; i < photoCount; i++) {
      final target = step * i;
      final lower = previous + minimum;
      final upper = total - minimum * (photoCount - i);
      var best = target.round().clamp(lower, upper);
      var bestScore = double.negativeInfinity;
      for (final candidate in times) {
        if (candidate < lower ||
            candidate > upper ||
            (candidate - target).abs() > step * 0.35) {
          continue;
        }
        final strength = maxStrength > 0
            ? (strengths[candidate] ?? 0) / maxStrength
            : 0;
        final score = strength * 0.4 - (candidate - target).abs() / step;
        if (score > bestScore) {
          bestScore = score;
          best = candidate;
        }
      }
      previous = best;
      result.add(Duration(microseconds: best));
    }
    result.add(end);
    return List.unmodifiable(result);
  }
}
