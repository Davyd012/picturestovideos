import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/editor_preview_view_model.dart';

void main() {
  test(
    'edited composition marks its prior render stale until refreshed',
    () async {
      final renderer = _ImmediateRenderer();
      final container = ProviderContainer(
        overrides: [
          previewRendererRepositoryProvider.overrideWithValue(renderer),
        ],
      );
      addTearDown(container.dispose);

      final original = _project(ImageCropTransform.centered);
      final edited = _project(
        const ImageCropTransform(focalX: 0.6, focalY: -0.3, zoom: 1.5),
      );
      final viewModel = container.read(editorPreviewViewModelProvider.notifier);

      await viewModel.renderPreview(original, audioSourcePath: null);
      final firstResult = container.read(editorPreviewViewModelProvider).result;
      expect(firstResult, isNotNull);
      expect(
        container.read(editorPreviewViewModelProvider).isRenderedPreviewStale,
        isFalse,
      );

      viewModel.syncPreview(edited, audioSourcePath: null);
      final staleState = container.read(editorPreviewViewModelProvider);
      expect(staleState.result, same(firstResult));
      expect(staleState.isRenderedPreviewStale, isTrue);

      await viewModel.renderPreview(edited, audioSourcePath: null);
      final refreshedState = container.read(editorPreviewViewModelProvider);
      expect(refreshedState.isReady, isTrue);
      expect(refreshedState.isRenderedPreviewStale, isFalse);
      expect(refreshedState.result?.outputPath, 'render-2.mp4');
    },
  );
}

ProjectTimeline _project(ImageCropTransform crop) {
  return ProjectTimeline(
    id: 'preview-freshness',
    name: 'Preview freshness',
    beatMap: const BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 1),
    ),
    tracks: [
      TimelineTrack(
        id: 'track-media',
        name: 'Images',
        events: [
          BeatEvent(
            time: Duration.zero,
            type: 'image',
            payload: MediaTrackClipPayload(
              clipId: 'one',
              mediaId: 'photo',
              title: 'Photo',
              tagline: '',
              start: Duration.zero,
              end: const Duration(seconds: 4),
              sourcePath: '/tmp/photo.jpg',
              imageFit: VideoTemplateImageFit.cover,
              cropTransform: crop,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ImmediateRenderer implements PreviewRendererRepository {
  var renderCount = 0;

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) async {
    renderCount++;
    return BuildPreviewVideoResult(
      outputPath: 'render-$renderCount.mp4',
      signature: 'renderer-signature-$renderCount',
      totalDuration: const Duration(seconds: 4),
      thumbnails: const [],
    );
  }
}
