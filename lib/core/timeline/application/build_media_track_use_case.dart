import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

final buildMediaTrackUseCaseProvider = Provider<BuildMediaTrackUseCase>(
  (ref) => const BuildMediaTrackUseCase(),
);

class BuildMediaTrackUseCase {
  const BuildMediaTrackUseCase();

  TimelineTrack? call({
    required BeatMap beatMap,
    required List<LibraryMediaItem> selectedMedia,
    required List<BeatEvent> markerEvents,
    VideoTemplate template = VideoTemplates.cleanMemories,
  }) {
    if (markerEvents.isEmpty || selectedMedia.isEmpty) {
      return null;
    }

    final sortedMarkers = [...markerEvents]
      ..sort((a, b) => a.time.compareTo(b.time));
    final events = <BeatEvent>[];

    for (var index = 0; index < sortedMarkers.length; index++) {
      final item = selectedMedia[index % selectedMedia.length];
      final start = sortedMarkers[index].time;
      final proposedEnd = index + 1 < sortedMarkers.length
          ? sortedMarkers[index + 1].time
          : start + _fallbackClipSpan(beatMap, template);
      final end = proposedEnd > start
          ? proposedEnd
          : start + _fallbackClipSpan(beatMap, template);

      events.add(
        BeatEvent(
          time: start,
          type: 'image',
          payload: MediaTrackClipPayload(
            mediaId: item.id,
            title: item.title,
            tagline: item.tagline,
            start: start,
            end: end,
            sourcePath: item.sourcePath,
          ),
        ),
      );
    }

    return TimelineTrack(
      id: 'track-media',
      name: 'Images',
      events: List.unmodifiable(events),
    );
  }

  Duration _fallbackClipSpan(BeatMap beatMap, VideoTemplate template) {
    if (template.defaultSlideDuration > Duration.zero) {
      return template.defaultSlideDuration;
    }
    if (beatMap.averageBeatInterval > Duration.zero) {
      return beatMap.averageBeatInterval;
    }
    return const Duration(milliseconds: 500);
  }
}
