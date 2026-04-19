import 'package:file_picker/file_picker.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';

class SystemAudioFilePicker implements AudioFilePicker {
  const SystemAudioFilePicker();

  @override
  Future<PickedAudioFile?> pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      allowedExtensions: const ['wav', 'wave'],
      type: FileType.custom,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.readFailed,
          message: 'Picked file could not be read into memory.',
        ),
      );
    }

    return PickedAudioFile(
      name: file.name,
      extension: (file.extension ?? '').toLowerCase(),
      bytes: bytes,
      path: file.path,
    );
  }
}
