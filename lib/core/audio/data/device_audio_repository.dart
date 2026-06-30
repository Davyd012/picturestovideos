import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/data/system_audio_file_picker.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

final audioFilePickerProvider = Provider<AudioFilePicker>(
  (ref) => SystemAudioFilePicker(logger: ref.watch(appLoggerProvider)),
);

final audioRepositoryProvider = Provider<AudioRepository>(
  (ref) => DeviceAudioRepository(
    filePicker: ref.watch(audioFilePickerProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

class DeviceAudioRepository implements AudioRepository {
  const DeviceAudioRepository({
    required AudioFilePicker filePicker,
    required AppLogger logger,
  }) : this._(filePicker, logger);

  const DeviceAudioRepository._(this._filePicker, this._logger);

  final AudioFilePicker _filePicker;
  final AppLogger _logger;

  @override
  Future<SelectedAudioFile?> importAudio() async {
    _logger.info('AudioRepository', 'Starting audio import');
    final pickedFile = await _filePicker.pickAudioFile();
    return _selectedFileFromPickedFile(pickedFile);
  }

  @override
  Future<SelectedAudioFile?> selectSong() async {
    _logger.info('AudioRepository', 'Starting song selection');
    final pickedFile = await _filePicker.pickSongFile();
    return _selectedFileFromPickedFile(pickedFile);
  }

  SelectedAudioFile? _selectedFileFromPickedFile(PickedAudioFile? pickedFile) {
    if (pickedFile == null) {
      _logger.warning('AudioRepository', 'Audio import returned no file');
      return null;
    }

    return SelectedAudioFile(
      source: AudioSource(
        fileName: pickedFile.name,
        fileExtension: pickedFile.extension,
        byteLength: pickedFile.byteLength,
        path: pickedFile.path,
      ),
      bytes: pickedFile.bytes,
    );
  }

  @override
  Future<SelectedAudioFile> importAudioFromPath(String path) async {
    return _importFromPath(path, validateForAnalysis: true);
  }

  @override
  Future<SelectedAudioFile> selectSongFromPath(String path) async {
    return _importFromPath(path, validateForAnalysis: false);
  }

  Future<SelectedAudioFile> _importFromPath(
    String path, {
    required bool validateForAnalysis,
  }) async {
    final normalizedPath = path.trim();
    _logger.info(
      'AudioRepository',
      'Importing audio from path $normalizedPath',
    );
    if (normalizedPath.isEmpty) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.readFailed,
          message: 'Enter a WAV file path before importing.',
        ),
      );
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.readFailed,
          message: 'No file exists at "$normalizedPath".',
        ),
      );
    }

    final bytes = await file.readAsBytes();
    final fileName = _fileNameForPath(normalizedPath);
    final extension = _extensionForFileName(fileName);
    if (validateForAnalysis && !_isSupportedManualExtension(extension)) {
      throw AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.unsupportedFormat,
          message: Platform.isAndroid
              ? 'Only WAV, MP3, AAC, and M4A files are supported for manual import.'
              : 'Only WAV files are supported for manual import.',
        ),
      );
    }

    return SelectedAudioFile(
      source: AudioSource(
        fileName: fileName,
        fileExtension: extension,
        byteLength: bytes.length,
        path: normalizedPath,
      ),
      bytes: bytes,
    );
  }

  String _fileNameForPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  String _extensionForFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  bool _isSupportedManualExtension(String extension) {
    if (extension == 'wav' || extension == 'wave') {
      return true;
    }
    return Platform.isAndroid &&
        (extension == 'mp3' || extension == 'm4a' || extension == 'aac');
  }
}
