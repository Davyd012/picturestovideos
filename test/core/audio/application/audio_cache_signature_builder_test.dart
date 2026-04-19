import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';

void main() {
  test('build creates stable signature for audio data', () {
    const builder = AudioCacheSignatureBuilder();
    const audioData = AudioData(
      samples: [0.1, 0.2, 0.3, 0.4],
      sampleRate: 44100,
      duration: Duration(milliseconds: 1000),
      channelCount: 1,
    );

    final signature = builder.build(audioData);

    expect(signature, contains('44100'));
    expect(signature, contains('1000'));
    expect(signature, contains('0.1000'));
  });
}
