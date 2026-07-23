import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/application/build_preview_video_use_case.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';

final editorPreviewViewModelProvider =
    NotifierProvider<EditorPreviewViewModel, EditorPreviewState>(
      EditorPreviewViewModel.new,
    );

class EditorPreviewViewModel extends Notifier<EditorPreviewState> {
  static const _tag = 'EditorPreviewViewModel';
  static const _previewFrameRate = 12;
  int _renderGeneration = 0;

  @override
  EditorPreviewState build() {
    ref.read(appLoggerProvider).info(_tag, 'Initializing editor preview state');
    return const EditorPreviewState.initial().copyWith(
      statusMessage:
          'Preview is waiting for a timeline. Import audio, add images, then rebuild the timeline to start preview generation.',
    );
  }

  void syncPreview(
    ProjectTimeline? project, {
    String? audioSourcePath,
    String? reason,
  }) {
    if (project == null) {
      _renderGeneration++;
      ref
          .read(appLoggerProvider)
          .debug(
            _tag,
            'Preview sync skipped because the editor has no project timeline yet',
          );
      state = state.copyWith(
        status: EditorPreviewStatus.idle,
        statusMessage:
            'Preview is waiting for a timeline. Import audio, add images, then rebuild the timeline to start preview generation.',
        clearResult: true,
        clearSignature: true,
        clearError: true,
      );
      return;
    }

    final clips = ref
        .read(resolvePreviewClipsUseCaseProvider)
        .call(beatMap: project.beatMap, project: project);
    if (clips.isEmpty) {
      _renderGeneration++;
      ref
          .read(appLoggerProvider)
          .debug(
            _tag,
            'Preview sync skipped because no preview clips could be resolved',
          );
      state = state.copyWith(
        status: EditorPreviewStatus.idle,
        statusMessage: 'Preview is waiting for marker-synced image clips.',
        clearResult: true,
        clearSignature: true,
        clearError: true,
      );
      return;
    }

    final signature = _buildPreviewSignature(
      projectId: project.id,
      clips: clips,
      audioSourcePath: audioSourcePath,
      template: project.template,
    );
    if (state.signature == signature && (state.isRendering || state.isReady)) {
      return;
    }
    if (state.signature == signature && state.isLive) {
      return;
    }

    _renderGeneration++;
    ref
        .read(appLoggerProvider)
        .info(
          _tag,
          'Live preview synced for ${clips.length} image clips${reason == null ? '' : ' ($reason)'}',
        );
    state = state.copyWith(
      status: EditorPreviewStatus.live,
      signature: signature,
      statusMessage:
          'Live preview ready with ${clips.length} marker-synced image clips.',
      clearError: true,
      clearResult: true,
    );
  }

  Future<void> renderPreview(
    ProjectTimeline? project, {
    String? audioSourcePath,
  }) async {
    if (project == null) {
      syncPreview(project, audioSourcePath: audioSourcePath);
      return;
    }

    final clips = ref
        .read(resolvePreviewClipsUseCaseProvider)
        .call(beatMap: project.beatMap, project: project);
    if (clips.isEmpty) {
      syncPreview(project, audioSourcePath: audioSourcePath);
      return;
    }

    final signature = _buildPreviewSignature(
      projectId: project.id,
      clips: clips,
      audioSourcePath: audioSourcePath,
      template: project.template,
    );
    if (state.signature == signature && (state.isRendering || state.isReady)) {
      return;
    }

    final renderGeneration = ++_renderGeneration;
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Rendering preview for ${clips.length} image clips');
    state = state.copyWith(
      status: EditorPreviewStatus.rendering,
      signature: signature,
      statusMessage:
          'Rendering ${clips.length} image clips into the preview video.',
      clearError: true,
      clearResult: true,
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
              frameRate: _previewFrameRate,
              template: project.template,
            ),
          );
      if (renderGeneration != _renderGeneration) {
        return;
      }
      state = state.copyWith(
        status: EditorPreviewStatus.ready,
        result: result,
        signature: result.signature,
        statusMessage: 'Preview video ready at ${result.outputPath}',
        clearError: true,
      );
    } catch (error, stackTrace) {
      final userMessage = error.toString().contains('ffmpeg')
          ? 'Video rendering failed. Check that the selected image and audio files are still available.'
          : 'Preview generation failed. Check the app logs for image render details.';
      ref
          .read(appLoggerProvider)
          .error(_tag, error, stackTrace, message: 'Preview generation failed');
      if (renderGeneration != _renderGeneration) {
        return;
      }
      state = state.copyWith(
        status: EditorPreviewStatus.failure,
        errorMessage: userMessage,
        statusMessage: userMessage,
        clearResult: true,
      );
    }
  }

  void invalidate() {
    _renderGeneration++;
    state = state.copyWith(
      status: EditorPreviewStatus.idle,
      statusMessage:
          'Preview has been invalidated. Waiting for the next timeline update.',
      clearResult: true,
      clearSignature: true,
      clearError: true,
    );
  }

  void clear() => invalidate();

  String _buildPreviewSignature({
    required String projectId,
    required List<MediaTrackClipPayload> clips,
    required String? audioSourcePath,
    required VideoTemplate template,
  }) {
    final renderSize = _renderSizeFor(template);
    return [
      projectId,
      _templateSignature(template),
      audioSourcePath ?? 'no-audio',
      '${renderSize.width}x${renderSize.height}',
      '$_previewFrameRate',
      for (final clip in clips)
        '${clip.mediaId}:${clip.start.inMilliseconds}:${clip.end.inMilliseconds}:${clip.title}:${clip.tagline}:${clip.sourcePath}:${clip.imageFit.name}:${clip.cropTransform.focalX}:${clip.cropTransform.focalY}:${clip.cropTransform.zoom}',
    ].join('|');
  }

  String _templateSignature(VideoTemplate template) {
    return template
        .toJson()
        .entries
        .map((entry) {
          return '${entry.key}:${entry.value}';
        })
        .join(';');
  }

  _RenderSize _renderSizeFor(VideoTemplate template) {
    return _RenderSize(
      width: template.aspectRatio.previewWidth,
      height: template.aspectRatio.previewHeight,
    );
  }
}

class _RenderSize {
  const _RenderSize({required this.width, required this.height});

  final int width;
  final int height;
}
