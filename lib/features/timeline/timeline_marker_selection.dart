class TimelineMarkerSelection {
  const TimelineMarkerSelection({required this.time, this.mediaId});

  final Duration time;
  final String? mediaId;

  bool matches({required Duration time, String? mediaId}) {
    return this.time == time &&
        (this.mediaId == null || this.mediaId == mediaId);
  }
}
