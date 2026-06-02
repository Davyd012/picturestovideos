import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/resolve_media_track_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

final resolvePreviewClipsUseCaseProvider = Provider<ResolvePreviewClipsUseCase>(
  (ref) => ResolvePreviewClipsUseCase(
    resolveMediaTrackClipsUseCase: ref.watch(
      resolveMediaTrackClipsUseCaseProvider,
    ),
  ),
);

class ResolvePreviewClipsUseCase {
  const ResolvePreviewClipsUseCase({
    required this._resolveMediaTrackClipsUseCase,
  });

  final ResolveMediaTrackClipsUseCase _resolveMediaTrackClipsUseCase;

  List<MediaTrackClipPayload> call({
    required BeatMap beatMap,
    required ProjectTimeline? project,
  }) {
    final mediaClips = _resolveMediaTrackClipsUseCase(
      beatMap: beatMap,
      project: project,
    );
    if (mediaClips.isNotEmpty) {
      return mediaClips;
    }
    return const [];
  }
}
