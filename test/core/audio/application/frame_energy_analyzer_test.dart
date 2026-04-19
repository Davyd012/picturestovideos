import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/frame_energy_analyzer.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';

void main() {
  group('FrameEnergyAnalyzer', () {
    test('chunks samples into time-aligned frames', () {
      const analyzer = FrameEnergyAnalyzer();
      const audioData = AudioData(
        samples: [1, 1, 0, 0],
        sampleRate: 4,
        duration: Duration(seconds: 1),
        channelCount: 1,
      );

      final frames = analyzer.analyze(
        audioData: audioData,
        config: const AudioAnalysisConfig(
          frameSize: 2,
          hopSize: 1,
          normalizeEnergies: false,
        ),
      );

      expect(frames.length, 4);
      expect(frames[0].time, Duration.zero);
      expect(frames[1].time, const Duration(milliseconds: 250));
      expect(frames[2].time, const Duration(milliseconds: 500));
      expect(frames[0].energy, 2);
      expect(frames[1].energy, 1);
      expect(frames[2].energy, 0);
      expect(frames[3].energy, 0);
    });

    test('normalizes energy values when requested', () {
      const analyzer = FrameEnergyAnalyzer();
      const audioData = AudioData(
        samples: [1, 1, 0.5, 0.5],
        sampleRate: 4,
        duration: Duration(seconds: 1),
        channelCount: 1,
      );

      final frames = analyzer.analyze(
        audioData: audioData,
        config: const AudioAnalysisConfig(
          frameSize: 2,
          hopSize: 2,
          normalizeEnergies: true,
        ),
      );

      expect(frames.length, 2);
      expect(frames[0].energy, 1);
      expect(frames[1].energy, closeTo(0.25, 0.0001));
    });
  });
}
