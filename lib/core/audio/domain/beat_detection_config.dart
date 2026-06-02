class BeatDetectionConfig {
  const BeatDetectionConfig({
    required this.sensitivity,
    required this.movingAverageWindow,
    required this.minBeatInterval,
  });

  const BeatDetectionConfig.defaults()
      : sensitivity = 1.35,
        movingAverageWindow = 4,
        minBeatInterval = const Duration(milliseconds: 180);

  final double sensitivity;
  final int movingAverageWindow;
  final Duration minBeatInterval;
}
