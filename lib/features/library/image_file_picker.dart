import 'dart:typed_data';

class PickedImageFile {
  const PickedImageFile({
    required this.name,
    required this.extension,
    required this.size,
    required this.path,
    this.bytes,
    this.modifiedOn,
  });

  final String name;
  final String extension;
  final int size;
  final String? path;
  final Uint8List? bytes;
  final DateTime? modifiedOn;
}

abstract interface class ImageFilePicker {
  Future<List<PickedImageFile>> pickImageFiles();
}
