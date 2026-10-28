import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';

void main() {
  test('range is limited by both source and video and fades are bounded', () {
    const mix = AudioMix(
      start: Duration(seconds: 2),
      end: Duration(seconds: 8),
      fadeIn: Duration(seconds: 2),
      fadeOut: Duration(seconds: 2),
    );
    const source = Duration(seconds: 6);
    const video = Duration(seconds: 3);
    expect(
      mix.effectiveDuration(sourceDuration: source, videoDuration: video),
      const Duration(seconds: 3),
    );
    expect(
      mix.volumeAt(Duration.zero, sourceDuration: source, videoDuration: video),
      0,
    );
    expect(
      mix.volumeAt(
        const Duration(milliseconds: 750),
        sourceDuration: source,
        videoDuration: video,
      ),
      closeTo(0.5, 0.0001),
    );
    expect(
      mix.volumeAt(
        const Duration(milliseconds: 1500),
        sourceDuration: source,
        videoDuration: video,
      ),
      1,
    );
    expect(
      mix.volumeAt(
        const Duration(seconds: 3),
        sourceDuration: source,
        videoDuration: video,
      ),
      0,
    );
    final decoded = AudioMix.fromJson(mix.toJson());
    expect(decoded.start, mix.start);
    expect(decoded.end, mix.end);
    expect(decoded.fadeOut, mix.fadeOut);
  });
}
