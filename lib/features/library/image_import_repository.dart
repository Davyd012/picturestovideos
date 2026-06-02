import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/library/image_file_picker.dart';
import 'package:picturestovideos/features/library/system_image_file_picker.dart';

final imageFilePickerProvider = Provider<ImageFilePicker>(
  (ref) => SystemImageFilePicker(logger: ref.watch(appLoggerProvider)),
);

final imageImportRepositoryProvider = Provider<ImageImportRepository>(
  (ref) => DeviceImageImportRepository(
    filePicker: ref.watch(imageFilePickerProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

class ImportedImageAsset {
  const ImportedImageAsset({
    required this.id,
    required this.fileName,
    required this.sourcePath,
    required this.bytes,
    required this.importedOn,
  });

  final String id;
  final String fileName;
  final String sourcePath;
  final Uint8List bytes;
  final DateTime importedOn;

  int get byteLength => bytes.length;
}

abstract interface class ImageImportRepository {
  Future<List<ImportedImageAsset>> pickImages();
  Future<List<ImportedImageAsset>> importImagesFromFolderPath(
    String folderPath,
  );
}

class DeviceImageImportRepository implements ImageImportRepository {
  const DeviceImageImportRepository({
    required ImageFilePicker filePicker,
    required AppLogger logger,
  }) : _filePicker = filePicker,
       _logger = logger;

  final ImageFilePicker _filePicker;
  final AppLogger _logger;

  static const _supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  @override
  Future<List<ImportedImageAsset>> pickImages() async {
    final pickedFiles = await _filePicker.pickImageFiles();
    final importedOn = DateTime.now();
    final assets = <ImportedImageAsset>[];

    for (final file in pickedFiles) {
      final path = file.path;
      if (path == null || path.trim().isEmpty) {
        continue;
      }
      if (!_isSupportedExtension(file.extension)) {
        continue;
      }

      assets.add(
        ImportedImageAsset(
          id: path,
          fileName: file.name,
          sourcePath: path,
          bytes: file.bytes,
          importedOn: importedOn,
        ),
      );
    }

    return List.unmodifiable(assets);
  }

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPath(
    String folderPath,
  ) async {
    final normalizedPath = folderPath.trim();
    if (normalizedPath.isEmpty) {
      throw const FormatException('Enter a folder path before importing.');
    }

    final directory = Directory(normalizedPath);
    if (!await directory.exists()) {
      throw FileSystemException(
        'No folder exists at the provided path.',
        normalizedPath,
      );
    }

    _logger.info(
      'ImageImportRepository',
      'Importing images from folder $normalizedPath',
    );

    final entities = await directory.list().toList();
    final files = entities.whereType<File>().toList(growable: false)
      ..sort(
        (a, b) => _fileNameForPath(
          a.path,
        ).toLowerCase().compareTo(_fileNameForPath(b.path).toLowerCase()),
      );

    final importedOn = DateTime.now();
    final assets = <ImportedImageAsset>[];

    for (final file in files) {
      final fileName = _fileNameForPath(file.path);
      final extension = _extensionForFileName(fileName);
      if (!_isSupportedExtension(extension)) {
        continue;
      }

      assets.add(
        ImportedImageAsset(
          id: file.path,
          fileName: fileName,
          sourcePath: file.path,
          bytes: await file.readAsBytes(),
          importedOn: importedOn,
        ),
      );
    }

    _logger.info(
      'ImageImportRepository',
      'Imported ${assets.length} images from folder $normalizedPath',
    );
    return List.unmodifiable(assets);
  }

  bool _isSupportedExtension(String extension) {
    return _supportedExtensions.contains(extension.toLowerCase());
  }

  String _fileNameForPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  String _extensionForFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}
