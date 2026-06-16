import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:share_plus/share_plus.dart';

final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => DeviceExportRepository(logger: ref.watch(appLoggerProvider)),
);

abstract interface class ExportRepository {
  Future<void> saveVideoToGallery(String outputPath);
  Future<void> shareVideo(String outputPath, {required String projectName});
}

class DeviceExportRepository implements ExportRepository {
  const DeviceExportRepository({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  @override
  Future<void> saveVideoToGallery(String outputPath) async {
    if (Platform.isLinux) {
      throw UnsupportedError('Gallery export is not available on Linux.');
    }

    _logger.info('ExportRepository', 'Saving video to gallery: $outputPath');
    await Gal.putVideo(outputPath, album: 'Pictures To Videos');
  }

  @override
  Future<void> shareVideo(
    String outputPath, {
    required String projectName,
  }) async {
    if (Platform.isLinux) {
      throw UnsupportedError('File sharing is not available on Linux.');
    }

    _logger.info('ExportRepository', 'Sharing video: $outputPath');
    await SharePlus.instance.share(
      ShareParams(
        title: projectName,
        text: projectName,
        files: [XFile(outputPath, mimeType: 'video/mp4')],
      ),
    );
  }
}
