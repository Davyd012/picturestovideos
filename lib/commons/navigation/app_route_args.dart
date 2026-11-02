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

enum ImageSettingsSection { framing, motion, text, timing }

class ImageSettingsRouteArgs {
  const ImageSettingsRouteArgs.forClip(
    this.clipId, {
    this.section = ImageSettingsSection.framing,
  }) : mediaId = null;
  const ImageSettingsRouteArgs.forQueuedMedia(this.mediaId)
    : clipId = null,
      section = ImageSettingsSection.framing;

  final String? clipId;
  final String? mediaId;
  final ImageSettingsSection section;
}
