import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/data/system_audio_file_picker.dart';
import 'package:picturestovideos/core/audio/data/wav_file_decoder.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_result.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';

final audioFilePickerProvider = Provider<AudioFilePicker>(
  (ref) => const SystemAudioFilePicker(),
);

final wavFileDecoderProvider = Provider<WavFileDecoder>(
  (ref) => const WavFileDecoder(),
);

final audioRepositoryProvider = Provider<AudioRepository>(
  (ref) => DeviceAudioRepository(
    filePicker: ref.watch(audioFilePickerProvider),
    wavFileDecoder: ref.watch(wavFileDecoderProvider),
  ),
);

class DeviceAudioRepository implements AudioRepository {
  const DeviceAudioRepository({
    required AudioFilePicker filePicker,
    required WavFileDecoder wavFileDecoder,
  })  : _filePicker = filePicker,
        _wavFileDecoder = wavFileDecoder;

  final AudioFilePicker _filePicker;
  final WavFileDecoder _wavFileDecoder;

  @override
  Future<AudioImportResult?> importAudio() async {
    final pickedFile = await _filePicker.pickAudioFile();
    if (pickedFile == null) {
      return null;
    }

    final audioData = _wavFileDecoder.decode(
      bytes: pickedFile.bytes,
    );

    return AudioImportResult(
      source: AudioSource(
        fileName: pickedFile.name,
        fileExtension: pickedFile.extension,
        byteLength: pickedFile.bytes.length,
        path: pickedFile.path,
      ),
      audioData: audioData,
    );
  }
}
