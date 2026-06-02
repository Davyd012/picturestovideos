import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

final prepareAudioForAnalysisUseCaseProvider =
    Provider<PrepareAudioForAnalysisUseCase>(
      (ref) =>
          PrepareAudioForAnalysisUseCase(logger: ref.watch(appLoggerProvider)),
    );

class PrepareAudioForAnalysisUseCase {
  const PrepareAudioForAnalysisUseCase({required AppLogger logger})
    : this._(logger);

  const PrepareAudioForAnalysisUseCase._(this._logger);

  final AppLogger _logger;
  static const _tag = 'PrepareAudioForAnalysisUseCase';

  Future<SelectedAudioFile> call(SelectedAudioFile selectedFile) async {
    if (_isRiffWave(selectedFile.bytes)) {
      return selectedFile;
    }

    if (!Platform.isAndroid) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.invalidFormat,
          message: 'Only RIFF/WAVE audio files are supported.',
        ),
      );
    }

    _logger.info(_tag, 'Converting selected Android audio to WAV for analysis');

    final wavBytes = await _convertAndroidAudioToWav(selectedFile);
    return SelectedAudioFile(source: selectedFile.source, bytes: wavBytes);
  }

  bool _isRiffWave(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    return _readAscii(bytes, 0) == 'RIFF' && _readAscii(bytes, 8) == 'WAVE';
  }

  String _readAscii(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }

  Future<Uint8List> _convertAndroidAudioToWav(
    SelectedAudioFile selectedFile,
  ) async {
    final tempRoot = await getTemporaryDirectory();
    final tempDir = await tempRoot.createTemp('picturestovideos-audio-');
    File? generatedInput;

    try {
      final sourcePath = selectedFile.source.path;
      final sourceFile = sourcePath == null || sourcePath.isEmpty
          ? null
          : File(sourcePath);
      final inputPath = sourceFile != null && sourceFile.existsSync()
          ? sourceFile.path
          : await _writeTemporaryInput(
              selectedFile: selectedFile,
              tempDir: tempDir,
            ).then((file) {
              generatedInput = file;
              return file.path;
            });
      final outputPath = '${tempDir.path}/analysis.wav';

      await FFmpegKitExtended.initialize();
      final args = [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-ac',
        '1',
        '-ar',
        '44100',
        '-c:a',
        'pcm_s16le',
        '-f',
        'wav',
        outputPath,
      ];
      final session = FFmpegKit.createSessionFromArguments(args);
      await session.executeAsync();

      final returnCode = session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        throw ProcessException(
          'ffmpeg-kit',
          args,
          [
            session.getOutput(),
            session.getLogsAsString(),
            session.getFailStackTrace(),
          ].whereType<String>().join('\n'),
          returnCode,
        );
      }

      final bytes = await File(outputPath).readAsBytes();
      return bytes;
    } on AudioImportException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        error,
        stackTrace,
        message: 'Android audio conversion failed',
      );
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.unsupportedFormat,
          message:
              'Selected audio could not be converted. Try a WAV, MP3, AAC, or M4A file.',
        ),
      );
    } finally {
      try {
        generatedInput?.deleteSync();
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  Future<File> _writeTemporaryInput({
    required SelectedAudioFile selectedFile,
    required Directory tempDir,
  }) async {
    final extension = selectedFile.source.fileExtension.trim().isEmpty
        ? 'audio'
        : selectedFile.source.fileExtension.trim();
    final input = File('${tempDir.path}/input.$extension');
    await input.writeAsBytes(selectedFile.bytes, flush: true);
    return input;
  }
}
