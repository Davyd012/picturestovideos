import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/wav_file_decoder.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_processing_task.dart';

final decodeWavAudioUseCaseProvider = Provider<DecodeWavAudioUseCase>(
  (ref) => const DecodeWavAudioUseCase(),
);

class DecodeWavAudioUseCase {
  const DecodeWavAudioUseCase();

  Future<AudioData> call({required DecodeWavAudioRequest request}) async {
    final result = await compute(_decodeWavAudioOnIsolate, request);
    return result.audioData;
  }
}

DecodeWavAudioResult _decodeWavAudioOnIsolate(DecodeWavAudioRequest request) {
  final audioData = const WavFileDecoder().decode(bytes: request.bytes);
  return DecodeWavAudioResult(audioData: audioData);
}
