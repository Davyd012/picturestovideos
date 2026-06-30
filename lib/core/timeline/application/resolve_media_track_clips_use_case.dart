import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

final resolveMediaTrackClipsUseCaseProvider =
    Provider<ResolveMediaTrackClipsUseCase>(
      (ref) => const ResolveMediaTrackClipsUseCase(),
    );

class ResolveMediaTrackClipsUseCase {
  const ResolveMediaTrackClipsUseCase();

  List<MediaTrackClipPayload> call({
    required BeatMap beatMap,
    required ProjectTimeline? project,
  }) {
    final mediaTrack = _resolveMediaTrack(project);
    if (mediaTrack == null || mediaTrack.events.isEmpty) {
      return const [];
    }

    final sortedEvents = [...mediaTrack.events]
      ..sort((a, b) => a.time.compareTo(b.time));
    final fallbackSpan = _fallbackBeatSpan(beatMap);
    final clips = <MediaTrackClipPayload>[];

    for (var index = 0; index < sortedEvents.length; index++) {
      final event = sortedEvents[index];
      final basePayload = _payloadFromEvent(event);
      if (basePayload == null) {
        continue;
      }

      final nextStart = index + 1 < sortedEvents.length
          ? sortedEvents[index + 1].time
          : event.time + fallbackSpan;
      final proposedEnd = basePayload.end > event.time
          ? basePayload.end
          : nextStart;
      final resolvedEnd = proposedEnd > event.time
          ? proposedEnd
          : event.time + fallbackSpan;

      clips.add(basePayload.copyWith(start: event.time, end: resolvedEnd));
    }

    return List.unmodifiable(clips);
  }

  TimelineTrack? _resolveMediaTrack(ProjectTimeline? project) {
    if (project == null || project.tracks.isEmpty) {
      return null;
    }

    for (final track in project.tracks) {
      if (track.id == 'track-media' && track.events.isNotEmpty) {
        return track;
      }
    }

    for (final track in project.tracks) {
      if (track.id != 'track-markers' && track.events.isNotEmpty) {
        return track;
      }
    }

    return null;
  }

  MediaTrackClipPayload? _payloadFromEvent(BeatEvent event) {
    final payload = event.payload;
    if (payload is MediaTrackClipPayload) {
      return payload;
    }
    if (payload is Map<String, Object?> &&
        payload['kind'] == 'media-track-clip') {
      return MediaTrackClipPayload.fromJson(payload);
    }
    if (payload is String) {
      final parts = payload.split('|');
      final title = parts.isNotEmpty ? parts.first : event.type;
      final endMs = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      final tagline = parts.length >= 3 ? parts[2] : '';
      final sourcePath = parts.length >= 4 ? parts[3] : '';
      return MediaTrackClipPayload(
        mediaId: title,
        title: title,
        tagline: tagline,
        start: event.time,
        end: Duration(milliseconds: endMs ?? event.time.inMilliseconds),
        sourcePath: sourcePath,
        imageFit: VideoTemplateImageFit.cover,
      );
    }
    return null;
  }

  Duration _fallbackBeatSpan(BeatMap beatMap) {
    if (beatMap.averageBeatInterval > Duration.zero) {
      return beatMap.averageBeatInterval;
    }
    return const Duration(milliseconds: 500);
  }
}
