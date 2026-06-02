import 'dart:typed_data';

class PickedImageFile {
  const PickedImageFile({
    required this.name,
    required this.extension,
    required this.bytes,
    required this.path,
  });

  final String name;
  final String extension;
  final Uint8List bytes;
  final String? path;
}

abstract interface class ImageFilePicker {
  Future<List<PickedImageFile>> pickImageFiles();
}
