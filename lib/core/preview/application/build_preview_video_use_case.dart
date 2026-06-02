import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';

final buildPreviewVideoUseCaseProvider = Provider<BuildPreviewVideoUseCase>(
  (ref) => BuildPreviewVideoUseCase(
    previewRendererRepository: ref.watch(previewRendererRepositoryProvider),
  ),
);

class BuildPreviewVideoUseCase {
  const BuildPreviewVideoUseCase({required this._previewRendererRepository});

  final PreviewRendererRepository _previewRendererRepository;

  Future<BuildPreviewVideoResult> call(BuildPreviewVideoRequest request) {
    return _previewRendererRepository.buildPreviewVideo(request);
  }
}
