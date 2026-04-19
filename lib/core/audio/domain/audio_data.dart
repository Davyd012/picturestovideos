class AudioData {
  const AudioData({
    required this.samples,
    required this.sampleRate,
    required this.duration,
    required this.channelCount,
  });

  final List<double> samples;
  final int sampleRate;
  final Duration duration;
  final int channelCount;
}
