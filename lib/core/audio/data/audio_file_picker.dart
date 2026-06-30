import 'dart:typed_data';

class PickedAudioFile {
  const PickedAudioFile({
    required this.name,
    required this.extension,
    required this.bytes,
    required this.byteLength,
    required this.path,
  });

  final String name;
  final String extension;
  final Uint8List bytes;
  final int byteLength;
  final String? path;
}

abstract interface class AudioFilePicker {
  Future<PickedAudioFile?> pickAudioFile();
  Future<PickedAudioFile?> pickSongFile();
}
