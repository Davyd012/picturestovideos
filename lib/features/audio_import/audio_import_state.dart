import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';

class AudioImportState {
  const AudioImportState({
    this.source,
    this.audioData,
  });

  const AudioImportState.initial()
      : source = null,
        audioData = null;

  final AudioSource? source;
  final AudioData? audioData;

  bool get hasAudio => source != null && audioData != null;
}
