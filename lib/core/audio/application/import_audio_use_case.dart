import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/device_audio_repository.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';

final importAudioUseCaseProvider = Provider<ImportAudioUseCase>(
  (ref) =>
      ImportAudioUseCase(audioRepository: ref.watch(audioRepositoryProvider)),
);

class ImportAudioUseCase {
  const ImportAudioUseCase({required AudioRepository audioRepository})
    : this._(audioRepository);

  const ImportAudioUseCase._(this._audioRepository);

  final AudioRepository _audioRepository;

  Future<SelectedAudioFile?> call() {
    return _audioRepository.importAudio();
  }

  Future<SelectedAudioFile> fromPath(String path) {
    return _audioRepository.importAudioFromPath(path);
  }
}
