import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

final resolveEditorPreviewFrameUseCaseProvider =
    Provider<ResolveEditorPreviewFrameUseCase>(
      (ref) => ResolveEditorPreviewFrameUseCase(
        resolvePreviewClipsUseCase: ref.watch(
          resolvePreviewClipsUseCaseProvider,
        ),
      ),
    );

class ResolveEditorPreviewFrameUseCase {
  const ResolveEditorPreviewFrameUseCase({
    required this._resolvePreviewClipsUseCase,
  });

  final ResolvePreviewClipsUseCase _resolvePreviewClipsUseCase;

  EditorPreviewFrame call({
    required BeatMap? beatMap,
    required ProjectTimeline? project,
    required Duration currentTime,
  }) {
    if (beatMap == null || project == null) {
      return const EditorPreviewFrame.empty();
    }

    final clips = _resolvePreviewClipsUseCase(
      beatMap: beatMap,
      project: project,
    );
    if (clips.isEmpty) {
      return const EditorPreviewFrame.empty();
    }

    var activeIndex = clips.length - 1;
    for (var index = 0; index < clips.length; index++) {
      final clip = clips[index];
      final isWithin = currentTime >= clip.start && currentTime < clip.end;
      if (isWithin || currentTime < clip.start) {
        activeIndex = index;
        break;
      }
    }

    final activeClip = clips[activeIndex];
    final nextClip = activeIndex + 1 < clips.length
        ? clips[activeIndex + 1]
        : null;
    final span = activeClip.end - activeClip.start;
    final elapsed = currentTime - activeClip.start;
    final progress = span <= Duration.zero
        ? 0.0
        : ((elapsed.inMicroseconds / span.inMicroseconds).clamp(
            0.0,
            1.0,
          )).toDouble();

    return EditorPreviewFrame(
      currentTime: currentTime,
      activeIndex: activeIndex,
      progress: progress,
      clips: clips,
      activeClip: activeClip,
      nextClip: nextClip,
    );
  }
}
