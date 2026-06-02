import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';

abstract interface class AudioRepository {
  Future<SelectedAudioFile?> importAudio();
  Future<SelectedAudioFile> importAudioFromPath(String path);
}
