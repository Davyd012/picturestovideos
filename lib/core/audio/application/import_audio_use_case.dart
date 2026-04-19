import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/device_audio_repository.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_result.dart';

final importAudioUseCaseProvider = Provider<ImportAudioUseCase>(
  (ref) => ImportAudioUseCase(
    audioRepository: ref.watch(audioRepositoryProvider),
  ),
);

class ImportAudioUseCase {
  const ImportAudioUseCase({
    required AudioRepository audioRepository,
  }) : _audioRepository = audioRepository;

  final AudioRepository _audioRepository;

  Future<AudioImportResult?> call() {
    return _audioRepository.importAudio();
  }
}
