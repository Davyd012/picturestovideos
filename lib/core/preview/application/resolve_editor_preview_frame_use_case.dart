import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
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
  ResolveEditorPreviewFrameUseCase({required this._resolvePreviewClipsUseCase});

  final ResolvePreviewClipsUseCase _resolvePreviewClipsUseCase;
  static const _evaluator = CompositionEvaluator();
  ProjectTimeline? _cachedProject;
  BeatMap? _cachedBeatMap;
  List<MediaTrackClipPayload>? _cachedClips;
  VideoComposition? _cachedComposition;

  EditorPreviewFrame call({
    required BeatMap? beatMap,
    required ProjectTimeline? project,
    required Duration currentTime,
  }) {
    if (beatMap == null || project == null) {
      return const EditorPreviewFrame.empty();
    }

    final cacheHit =
        identical(project, _cachedProject) &&
        identical(beatMap, _cachedBeatMap);
    final clips = cacheHit
        ? _cachedClips!
        : _resolvePreviewClipsUseCase(beatMap: beatMap, project: project);
    if (clips.isEmpty) {
      return const EditorPreviewFrame.empty();
    }

    final composition = cacheHit
        ? _cachedComposition!
        : VideoComposition.fromProject(
            project: project,
            committedClips: clips,
            width: project.template.aspectRatio.previewWidth,
            height: project.template.aspectRatio.previewHeight,
            frameRate: 30,
          ).quantizedForOutput();
    if (!cacheHit) {
      _cachedProject = project;
      _cachedBeatMap = beatMap;
      _cachedClips = clips;
      _cachedComposition = composition;
    }
    final evaluated = _evaluator.evaluate(composition, currentTime);
    if (evaluated.layers.isEmpty) {
      return const EditorPreviewFrame.empty();
    }
    final activeClip = evaluated.layers.last.clip.toPayload();
    final activeIndex = clips.indexWhere(
      (clip) => clip.clipId == activeClip.clipId,
    );
    final nextClip = activeIndex >= 0 && activeIndex + 1 < clips.length
        ? clips[activeIndex + 1]
        : null;
    final progress = evaluated.layers.last.progress;
    ClipTransition? transition;
    MediaTrackClipPayload? outgoing;
    MediaTrackClipPayload? incoming;
    if (evaluated.layers.length == 2) {
      outgoing = evaluated.layers.first.clip.toPayload();
      incoming = evaluated.layers.last.clip.toPayload();
      transition = ClipTransition.between(outgoing, incoming, project.template);
    }

    return EditorPreviewFrame(
      currentTime: evaluated.time,
      activeIndex: activeIndex,
      progress: progress,
      clips: clips,
      activeClip: activeClip,
      nextClip: nextClip,
      transition: transition,
      transitionOutgoing: outgoing,
      transitionIncoming: incoming,
      transitionProgress: evaluated.transitionProgress,
      compositionFrame: evaluated,
    );
  }
}
