class SavedImageAsset {
  const SavedImageAsset({
    required this.id,
    required this.fileName,
    required this.sourcePath,
    required this.byteLength,
    required this.importedOn,
  });

  final String id;
  final String fileName;
  final String sourcePath;
  final int byteLength;
  final DateTime importedOn;
}
