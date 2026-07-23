class SavedImageAsset {
  const SavedImageAsset({
    required this.id,
    required this.fileName,
    required this.sourcePath,
    required this.byteLength,
    required this.importedOn,
    this.fileModifiedOn,
    this.importOrder = 0,
  });

  final String id;
  final String fileName;
  final String sourcePath;
  final int byteLength;
  final DateTime importedOn;
  final DateTime? fileModifiedOn;
  final int importOrder;
}
