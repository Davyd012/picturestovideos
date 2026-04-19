import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';

class AudioImportResult {
  const AudioImportResult({
    required this.source,
    required this.audioData,
  });

  final AudioSource source;
  final AudioData audioData;
}
