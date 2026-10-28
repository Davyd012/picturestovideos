import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

Set<String> unusedImportedImagePaths({
  required Iterable<SavedImageAsset> assets,
  required Set<String> removedIds,
  required Iterable<ProjectTimeline> projects,
}) {
  final removedPaths = {
    for (final asset in assets)
      if (removedIds.contains(asset.id)) asset.sourcePath,
  };
  return unreferencedImportedImagePaths(
    candidates: removedPaths,
    retainedAssets: assets.where((asset) => !removedIds.contains(asset.id)),
    projects: projects,
  );
}

Set<String> unreferencedImportedImagePaths({
  required Iterable<String> candidates,
  required Iterable<SavedImageAsset> retainedAssets,
  required Iterable<ProjectTimeline> projects,
}) {
  final candidatePaths = candidates.toSet();
  if (candidatePaths.isEmpty) return const {};

  final referencedPaths = <String>{};
  referencedPaths.addAll(retainedAssets.map((asset) => asset.sourcePath));
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
  return candidatePaths.difference(referencedPaths);
}
