import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

PreviewRendererRepository createPreviewRendererRepository(AppLogger logger) {
  return const _UnsupportedPreviewRendererRepository();
}

class _UnsupportedPreviewRendererRepository
    implements PreviewRendererRepository {
  const _UnsupportedPreviewRendererRepository();

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) {
    throw const RenderCapabilityException(
      RenderCapabilityIssue.unsupportedPlatform,
    );
  }
}
