import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';

final audioCacheSignatureBuilderProvider = Provider<AudioCacheSignatureBuilder>(
  (ref) => const AudioCacheSignatureBuilder(),
);

class AudioCacheSignatureBuilder {
  const AudioCacheSignatureBuilder();

  String build(AudioData audioData) {
    final samples = audioData.samples;
    final head = samples.take(8).map(_formatSample).join(',');
    final tail = samples
        .skip(samples.length > 8 ? samples.length - 8 : 0)
        .map(_formatSample)
        .join(',');

    return [
      audioData.sampleRate,
      audioData.duration.inMilliseconds,
      audioData.channelCount,
      samples.length,
      head,
      tail,
    ].join('|');
  }

  String _formatSample(double value) {
    return value.toStringAsFixed(4);
  }
}
