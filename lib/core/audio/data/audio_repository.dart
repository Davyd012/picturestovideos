import 'package:picturestovideos/core/audio/domain/audio_import_result.dart';

abstract interface class AudioRepository {
  Future<AudioImportResult?> importAudio();
}
