import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

typedef MarkerAssignmentTarget = ({
  MediaTrackClipPayload? clip,
  LibraryMediaItem? item,
});

List<MarkerAssignmentTarget> markerAssignmentTargets(
  ProjectTimeline? project,
  List<LibraryMediaItem> selectedMedia,
) {
  final events = [
    for (final track in project?.tracks ?? const [])
      if (track.id == 'track-media')
        for (final event in track.events)
          if (event.payload is MediaTrackClipPayload) event,
  ]..sort((a, b) => a.time.compareTo(b.time));
  final clips = [
    for (final event in events) event.payload as MediaTrackClipPayload,
  ];
  final remaining = [...clips];
  final queued = <LibraryMediaItem>[];
  for (final item in selectedMedia) {
    final index = remaining.indexWhere((clip) => clip.mediaId == item.id);
    if (index < 0) {
      queued.add(item);
    } else {
      remaining.removeAt(index);
    }
  }
  return [
    for (final clip in clips) (clip: clip, item: null),
    for (final item in queued) (clip: null, item: item),
  ];
}
