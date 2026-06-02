import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

class SystemAudioFilePicker implements AudioFilePicker {
  const SystemAudioFilePicker({required this._logger});

  final AppLogger _logger;

  @override
  Future<PickedAudioFile?> pickAudioFile() async {
    _logger.info('AudioFilePicker', 'Opening system audio picker');
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        allowMultiple: false,
        allowedExtensions: _supportedExtensions,
        type: FileType.custom,
        withData: true,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'AudioFilePicker',
        error,
        stackTrace,
        message: 'System audio picker failed',
      );
      final errorText = error.toString();
      if (errorText.contains('org.freedesktop.portal.Desktop') ||
          errorText.contains('DBus.Error.TimedOut')) {
        throw const AudioImportException(
          AudioImportFailure(
            type: AudioImportFailureType.readFailed,
            message:
                'The Linux system file picker is unavailable in this environment. Use "Import from path" and paste the WAV file path instead.',
          ),
        );
      }
      rethrow;
    }

    if (result == null || result.files.isEmpty) {
      _logger.warning('AudioFilePicker', 'Audio pick canceled');
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _logger.warning('AudioFilePicker', 'Picked file bytes were unavailable');
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.readFailed,
          message: 'Picked file could not be read into memory.',
        ),
      );
    }

    _logger.info('AudioFilePicker', 'Picked ${file.name}');
    return PickedAudioFile(
      name: file.name,
      extension: (file.extension ?? '').toLowerCase(),
      bytes: bytes,
      path: file.path,
    );
  }

  List<String> get _supportedExtensions {
    if (Platform.isAndroid) {
      return const ['wav', 'wave', 'mp3', 'm4a', 'aac'];
    }
    return const ['wav', 'wave'];
  }
}
