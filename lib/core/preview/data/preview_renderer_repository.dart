import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository_factory.dart'
    as preview_renderer_factory;
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';

final previewRendererRepositoryProvider = Provider<PreviewRendererRepository>(
  (ref) => preview_renderer_factory.createPreviewRendererRepository(
    ref.watch(appLoggerProvider),
  ),
);

abstract class PreviewRendererRepository {
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request,
  );
}
