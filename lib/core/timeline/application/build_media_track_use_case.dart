import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
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
          : start + _fallbackBeatSpan(beatMap);
      final end = proposedEnd > start
          ? proposedEnd
          : start + _fallbackBeatSpan(beatMap);

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

  Duration _fallbackBeatSpan(BeatMap beatMap) {
    if (beatMap.averageBeatInterval > Duration.zero) {
      return beatMap.averageBeatInterval;
    }
    return const Duration(milliseconds: 500);
  }
}
