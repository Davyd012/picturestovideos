import 'dart:typed_data';

import 'package:picturestovideos/features/library/image_import_repository.dart';

class LibraryMediaItem {
  const LibraryMediaItem({
    required this.id,
    required this.title,
    required this.sizeLabel,
    required this.tagline,
    required this.importedOnLabel,
    required this.importedOn,
    required this.byteLength,
    required this.thumbnailBytes,
    required this.sourcePath,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String sizeLabel;
  final String tagline;
  final String importedOnLabel;
  final DateTime importedOn;
  final int byteLength;
  final Uint8List thumbnailBytes;
  final String sourcePath;
  final bool isFavorite;

  factory LibraryMediaItem.fromImportedImageAsset(ImportedImageAsset asset) {
    return LibraryMediaItem(
      id: asset.id,
      title: asset.fileName,
      sizeLabel: _sizeLabel(asset.byteLength),
      tagline: 'Ready for beat-synced image clips',
      importedOnLabel: _dateLabel(asset.importedOn),
      importedOn: asset.importedOn,
      byteLength: asset.byteLength,
      thumbnailBytes: asset.thumbnailBytes,
      sourcePath: asset.sourcePath,
    );
  }

  static String _dateLabel(DateTime value) {
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthLabels[value.month - 1];
    final day = value.day.toString().padLeft(2, '0');
    return '$month $day, ${value.year}';
  }

  static String _sizeLabel(int byteLength) {
    if (byteLength < 1024 * 1024) {
      return '${(byteLength / 1024).toStringAsFixed(1)} KB';
    }
    return '${(byteLength / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
