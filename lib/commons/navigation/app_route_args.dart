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
