import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/playback_sync_result.dart';

final playbackCoordinatorProvider = Provider<PlaybackCoordinator>(
  (ref) => const PlaybackCoordinator(),
);

class PlaybackCoordinator {
  const PlaybackCoordinator();

  PlaybackSyncResult synchronize({
    required BeatMap beatMap,
    required Duration currentTime,
    required int nextBeatIndex,
    Duration tolerance = const Duration(milliseconds: 40),
  }) {
    if (nextBeatIndex < 0) {
      throw ArgumentError.value(
        nextBeatIndex,
        'nextBeatIndex',
        'Next beat index must not be negative.',
      );
    }

    final beats = beatMap.beats;
    if (beats.isEmpty || nextBeatIndex >= beats.length) {
      return PlaybackSyncResult(
        triggeredBeats: const [],
        nextBeatIndex: beats.length,
      );
    }

    final triggeredBeats = <Beat>[];
    var index = nextBeatIndex;
    while (index < beats.length) {
      final beat = beats[index];
      if (beat.time > currentTime + tolerance) {
        break;
      }

      if ((beat.time - currentTime).abs() <= tolerance ||
          beat.time < currentTime - tolerance) {
        triggeredBeats.add(beat);
        index += 1;
        continue;
      }

      break;
    }

    return PlaybackSyncResult(
      triggeredBeats: List.unmodifiable(triggeredBeats),
      nextBeatIndex: index,
    );
  }
}
