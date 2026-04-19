class AudioFrame {
  const AudioFrame({
    required this.time,
    required this.energy,
  });

  final Duration time;
  final double energy;
}
