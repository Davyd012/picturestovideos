class PlannedScreenArgs {
  const PlannedScreenArgs({
    required this.title,
    required this.route,
    required this.referenceFile,
    required this.recommendedStartOrder,
    required this.summary,
  });

  final String title;
  final String route;
  final String referenceFile;
  final int recommendedStartOrder;
  final String summary;
}

class ImageSettingsRouteArgs {
  const ImageSettingsRouteArgs.forClip(this.clipId) : mediaId = null;
  const ImageSettingsRouteArgs.forQueuedMedia(this.mediaId) : clipId = null;

  final String? clipId;
  final String? mediaId;
}
