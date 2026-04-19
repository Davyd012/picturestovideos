import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/playback_coordinator.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';

void main() {
  group('PlaybackCoordinator', () {
    test('triggers beats once using forward-only index progression', () {
      const coordinator = PlaybackCoordinator();
      const beatMap = BeatMap(
        beats: [
          Beat(
            time: Duration(milliseconds: 200),
            strength: 1.4,
          ),
          Beat(
            time: Duration(milliseconds: 500),
            strength: 1.6,
          ),
        ],
        bpm: 120,
        averageBeatInterval: Duration(milliseconds: 500),
      );

      final firstSync = coordinator.synchronize(
        beatMap: beatMap,
        currentTime: const Duration(milliseconds: 210),
        nextBeatIndex: 0,
      );
      final secondSync = coordinator.synchronize(
        beatMap: beatMap,
        currentTime: const Duration(milliseconds: 520),
        nextBeatIndex: firstSync.nextBeatIndex,
      );

      expect(firstSync.triggeredBeats.length, 1);
      expect(firstSync.triggeredBeats.first.time, const Duration(milliseconds: 200));
      expect(firstSync.nextBeatIndex, 1);
      expect(secondSync.triggeredBeats.length, 1);
      expect(secondSync.triggeredBeats.first.time, const Duration(milliseconds: 500));
      expect(secondSync.nextBeatIndex, 2);
    });

    test('respects tolerance boundary when deciding beat trigger', () {
      const coordinator = PlaybackCoordinator();
      const beatMap = BeatMap(
        beats: [
          Beat(
            time: Duration(milliseconds: 200),
            strength: 1.4,
          ),
        ],
        bpm: 120,
        averageBeatInterval: Duration(milliseconds: 500),
      );

      final syncResult = coordinator.synchronize(
        beatMap: beatMap,
        currentTime: const Duration(milliseconds: 120),
        nextBeatIndex: 0,
        tolerance: const Duration(milliseconds: 40),
      );

      expect(syncResult.triggeredBeats, isEmpty);
      expect(syncResult.nextBeatIndex, 0);
    });
  });
}
