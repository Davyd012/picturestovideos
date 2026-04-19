class AudioAnalysisConfig {
  const AudioAnalysisConfig({
    required this.frameSize,
    required this.hopSize,
    required this.normalizeEnergies,
  });

  const AudioAnalysisConfig.defaults()
      : frameSize = 1024,
        hopSize = 512,
        normalizeEnergies = false;

  final int frameSize;
  final int hopSize;
  final bool normalizeEnergies;
}
