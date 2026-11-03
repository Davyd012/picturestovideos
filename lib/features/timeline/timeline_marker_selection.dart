class TimelineMarkerSelection {
  const TimelineMarkerSelection({
    required this.time,
    this.mediaId,
    this.markerId,
  });

  final Duration time;
  final String? mediaId;
  final String? markerId;

  bool matches({required Duration time, String? mediaId}) {
    return this.time == time &&
        (this.mediaId == null || this.mediaId == mediaId);
  }
}
