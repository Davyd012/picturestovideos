import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

Set<String> unusedImportedImagePaths({
  required Iterable<SavedImageAsset> assets,
  required Set<String> removedIds,
  required Iterable<ProjectTimeline> projects,
}) {
  final candidates = {
    for (final asset in assets)
      if (removedIds.contains(asset.id)) asset.sourcePath,
  };
  if (candidates.isEmpty) return const {};

  final referencedPaths = <String>{};
  for (final project in projects) {
    for (final track in project.tracks) {
      for (final event in track.events) {
        final payload = event.payload;
        if (payload is MediaTrackClipPayload) {
          referencedPaths.add(payload.sourcePath);
        }
      }
    }
  }
  return candidates.difference(referencedPaths);
}
