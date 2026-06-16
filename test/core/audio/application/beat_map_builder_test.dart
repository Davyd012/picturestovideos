import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/beat_map_builder.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';

void main() {
  group('BeatMapBuilder', () {
    test('builds bpm from average beat interval', () {
      const builder = BeatMapBuilder();
      final beatMap = builder.build(
        beats: const [
          Beat(time: Duration(milliseconds: 0), strength: 1.2),
          Beat(time: Duration(milliseconds: 500), strength: 1.4),
          Beat(time: Duration(milliseconds: 1000), strength: 1.3),
        ],
      );

      expect(beatMap.beats.length, 3);
      expect(beatMap.averageBeatInterval, const Duration(milliseconds: 500));
      expect(beatMap.bpm, closeTo(120, 0.001));
    });

    test('returns zero bpm for fewer than two beats', () {
      const builder = BeatMapBuilder();
      final beatMap = builder.build(
        beats: const [Beat(time: Duration(milliseconds: 250), strength: 1.0)],
      );

      expect(beatMap.bpm, 0);
      expect(beatMap.averageBeatInterval, Duration.zero);
    });
  });
}
