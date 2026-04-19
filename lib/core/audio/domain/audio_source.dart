class AudioSource {
  const AudioSource({
    required this.fileName,
    required this.fileExtension,
    required this.byteLength,
    required this.path,
  });

  final String fileName;
  final String fileExtension;
  final int byteLength;
  final String? path;
}
