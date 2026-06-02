import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/application/build_preview_video_use_case.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/export/export_repository.dart';
import 'package:picturestovideos/features/export/export_state.dart';

final exportViewModelProvider = NotifierProvider<ExportViewModel, ExportState>(
  ExportViewModel.new,
);

class ExportViewModel extends Notifier<ExportState> {
  static const _tag = 'ExportViewModel';
  static const _exportLandscapeWidth = 1920;
  static const _exportLandscapeHeight = 1080;
  static const _exportPortraitWidth = 1080;
  static const _exportPortraitHeight = 1920;
  static const _exportFrameRate = 30;

  @override
  ExportState build() {
    ref.read(appLoggerProvider).info(_tag, 'Initializing export state');
    return const ExportState.initial();
  }

  Future<void> renderExport({
    required ProjectTimeline? project,
    required String? audioSourcePath,
  }) async {
    if (state.isRendering || state.isSaving || state.isSharing) {
      return;
    }
    if (project == null) {
      state = const ExportState(
        status: ExportStatus.failure,
        statusMessage: 'Build the timeline before exporting.',
        errorMessage: 'Build the timeline before exporting.',
      );
      return;
    }

    final clips = ref
        .read(resolvePreviewClipsUseCaseProvider)
        .call(beatMap: project.beatMap, project: project);
    if (clips.isEmpty) {
      state = const ExportState(
        status: ExportStatus.failure,
        statusMessage: 'Add beat-synced image clips before exporting.',
        errorMessage: 'Add beat-synced image clips before exporting.',
      );
      return;
    }

    state = state.copyWith(
      status: ExportStatus.rendering,
      statusMessage: 'Rendering 1080p MP4 export.',
      clearResult: true,
      clearError: true,
    );

    try {
      final renderSize = _renderSizeFor(project.template);
      final result = await ref
          .read(buildPreviewVideoUseCaseProvider)
          .call(
            BuildPreviewVideoRequest(
              projectId: project.id,
              clips: clips,
              audioSourcePath: audioSourcePath,
              width: renderSize.width,
              height: renderSize.height,
              frameRate: _exportFrameRate,
              template: project.template,
              outputFileName: _outputFileName(project.name),
            ),
          );
      state = state.copyWith(
        status: ExportStatus.ready,
        result: result,
        statusMessage: 'Export ready at ${result.outputPath}',
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(_tag, error, stackTrace, message: 'Export render failed');
      state = ExportState(
        status: ExportStatus.failure,
        statusMessage: _userMessageFor(error),
        errorMessage: _userMessageFor(error),
      );
    }
  }

  Future<void> saveToGallery() async {
    final result = state.result;
    if (result == null || state.isRendering || state.isSaving) {
      return;
    }

    state = state.copyWith(
      status: ExportStatus.saving,
      statusMessage: 'Saving export to gallery.',
      clearError: true,
    );

    try {
      await ref
          .read(exportRepositoryProvider)
          .saveVideoToGallery(result.outputPath);
      state = state.copyWith(
        status: ExportStatus.saved,
        statusMessage: 'Export saved to gallery.',
        result: result,
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(_tag, error, stackTrace, message: 'Gallery save failed');
      state = state.copyWith(
        status: ExportStatus.failure,
        statusMessage: _userMessageFor(error),
        errorMessage: _userMessageFor(error),
      );
    }
  }

  Future<void> shareExport({required String projectName}) async {
    final result = state.result;
    if (result == null || state.isRendering || state.isSharing) {
      return;
    }

    state = state.copyWith(
      status: ExportStatus.sharing,
      statusMessage: 'Opening share sheet.',
      clearError: true,
    );

    try {
      await ref
          .read(exportRepositoryProvider)
          .shareVideo(result.outputPath, projectName: projectName);
      state = state.copyWith(
        status: ExportStatus.ready,
        statusMessage: 'Export is ready to share again.',
        result: result,
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(_tag, error, stackTrace, message: 'Share failed');
      state = state.copyWith(
        status: ExportStatus.failure,
        statusMessage: _userMessageFor(error),
        errorMessage: _userMessageFor(error),
      );
    }
  }

  String _outputFileName(String projectName) {
    final safeProjectName = projectName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final name = safeProjectName.isEmpty ? 'picturestovideos' : safeProjectName;
    return '${name}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  String _userMessageFor(Object error) {
    final errorText = error.toString();
    if (errorText.contains('ffmpeg') || errorText.contains('FFmpeg')) {
      return 'Video rendering failed. Check that the selected image and audio files are still available.';
    }
    if (errorText.contains('Gallery') || errorText.contains('gallery')) {
      return 'Gallery save failed. Check photo access and available storage.';
    }
    if (errorText.contains('Sharing') || errorText.contains('sharing')) {
      return 'Sharing failed on this device.';
    }
    return 'Export failed. Check the app logs for details.';
  }

  _RenderSize _renderSizeFor(VideoTemplate template) {
    if (template.aspectRatio == VideoTemplateAspectRatio.portrait) {
      return const _RenderSize(
        width: _exportPortraitWidth,
        height: _exportPortraitHeight,
      );
    }
    return const _RenderSize(
      width: _exportLandscapeWidth,
      height: _exportLandscapeHeight,
    );
  }
}

class _RenderSize {
  const _RenderSize({required this.width, required this.height});

  final int width;
  final int height;
}
