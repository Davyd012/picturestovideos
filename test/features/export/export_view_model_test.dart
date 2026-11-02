import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/export/export_state.dart';
import 'package:picturestovideos/features/export/export_view_model.dart';

void main() {
  test('cancelled render cannot be saved or shared', () async {
    final renderer = _PendingRenderer();
    final container = ProviderContainer(
      overrides: [
        previewRendererRepositoryProvider.overrideWithValue(renderer),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectTimeline(
      id: 'cancel',
      name: 'Cancel',
      beatMap: BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 2),
      ),
      tracks: [
        TimelineTrack(
          id: 'media',
          name: 'Images',
          events: [
            BeatEvent(
              time: Duration.zero,
              type: 'image',
              payload: MediaTrackClipPayload(
                clipId: 'clip',
                mediaId: 'image',
                title: 'Image',
                tagline: '',
                start: Duration.zero,
                end: Duration(seconds: 2),
                sourcePath: '/tmp/image.jpg',
                imageFit: VideoTemplateImageFit.cover,
              ),
            ),
          ],
        ),
      ],
    );
    final notifier = container.read(exportViewModelProvider.notifier);
    final render = notifier.renderExport(
      project: project,
      audioSourcePath: null,
    );
    renderer.onProgress!(const BuildPreviewVideoProgress(
      completedSteps: 1, totalSteps: 4, currentStepLabel: 'Rendering',
    ));
    expect(container.read(exportViewModelProvider).renderProgress?.percent, 25);
    notifier.cancelRender();
    expect(renderer.cancellation?.isCancelled, isTrue);
    expect(
      container.read(exportViewModelProvider).status,
      ExportStatus.cancelling,
    );
    renderer.result.completeError(const RenderCancelled());
    await render;
    final state = container.read(exportViewModelProvider);
    expect(state.status, ExportStatus.cancelled);
    expect(state.result, isNull);
    expect(state.canSave, isFalse);
    expect(state.canShare, isFalse);
  });

  test('renders manually timed clips without beat events', () async {
    final renderer = _FakePreviewRendererRepository();
    final container = ProviderContainer(
      overrides: [
        previewRendererRepositoryProvider.overrideWithValue(renderer),
      ],
    );
    addTearDown(container.dispose);

    const project = ProjectTimeline(
      id: 'manual-project',
      name: 'Manual Project',
      beatMap: BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 2),
      ),
      tracks: [
        TimelineTrack(
          id: 'track-media',
          name: 'Images',
          events: [
            BeatEvent(
              time: Duration(seconds: 1),
              type: 'image',
              payload: MediaTrackClipPayload(
                clipId: 'clip',
                mediaId: 'image',
                title: 'Image',
                tagline: '',
                start: Duration(seconds: 1),
                end: Duration(seconds: 4),
                sourcePath: '/tmp/image.jpg',
                imageFit: VideoTemplateImageFit.cover,
              ),
            ),
          ],
        ),
      ],
    );

    await container
        .read(exportViewModelProvider.notifier)
        .renderExport(project: project, audioSourcePath: '/tmp/song.mp3');

    final state = container.read(exportViewModelProvider);
    expect(state.status, ExportStatus.ready);
    expect(renderer.request?.clips, hasLength(1));
    expect(renderer.request?.audioSourcePath, '/tmp/song.mp3');
  });
}

class _PendingRenderer implements PreviewRendererRepository {
  final result = Completer<BuildPreviewVideoResult>();
  RenderCancellation? cancellation;
  BuildPreviewVideoProgressCallback? onProgress;

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) {
    this.cancellation = cancellation;
    this.onProgress = onProgress;
    return result.future;
  }
}

class _FakePreviewRendererRepository implements PreviewRendererRepository {
  BuildPreviewVideoRequest? request;

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) async {
    this.request = request;
    return const BuildPreviewVideoResult(
      outputPath: '/tmp/manual.mp4',
      signature: 'manual',
      totalDuration: Duration(seconds: 4),
      thumbnails: [],
    );
  }
}
