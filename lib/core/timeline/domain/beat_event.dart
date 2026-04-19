class BeatEvent {
  const BeatEvent({
    required this.time,
    required this.type,
    this.payload,
  });

  final Duration time;
  final String type;
  final Object? payload;
}
