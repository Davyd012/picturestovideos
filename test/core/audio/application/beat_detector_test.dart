import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';

void main() {
  group('BeatDetector', () {
    test('detects peaks above adaptive threshold', () {
      const detector = BeatDetector();
      final frames = [
        _frame(0, 0.2),
        _frame(100, 0.3),
        _frame(200, 1.4),
        _frame(300, 0.2),
        _frame(400, 0.3),
        _frame(500, 1.6),
        _frame(600, 0.2),
      ];

      final beats = detector.detect(
        frames: frames,
        config: const BeatDetectionConfig(
          sensitivity: 1.3,
          movingAverageWindow: 3,
          minBeatInterval: Duration(milliseconds: 150),
        ),
      );

      expect(beats.length, 2);
      expect(beats[0].time, const Duration(milliseconds: 200));
      expect(beats[1].time, const Duration(milliseconds: 500));
      expect(beats[0].strength, greaterThan(1));
    });

    test('filters duplicate nearby peaks with minimum beat interval', () {
      const detector = BeatDetector();
      final frames = [
        _frame(0, 0.2),
        _frame(100, 1.3),
        _frame(200, 1.2),
        _frame(300, 0.2),
        _frame(600, 1.5),
      ];

      final beats = detector.detect(
        frames: frames,
        config: const BeatDetectionConfig(
          sensitivity: 1.1,
          movingAverageWindow: 2,
          minBeatInterval: Duration(milliseconds: 250),
        ),
      );

      expect(beats.length, 2);
      expect(beats[0].time, const Duration(milliseconds: 100));
      expect(beats[1].time, const Duration(milliseconds: 600));
    });
  });
}

AudioFrame _frame(int milliseconds, double energy) {
  return AudioFrame(
    time: Duration(milliseconds: milliseconds),
    energy: energy,
  );
}
