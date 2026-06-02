import 'dart:typed_data';

typedef BuildPreviewVideoProgressCallback =
    void Function(BuildPreviewVideoProgress progress);

class BuildPreviewVideoProgress {
  const BuildPreviewVideoProgress({
    required this.completedSteps,
    required this.totalSteps,
    required this.currentStepLabel,
    this.currentStepProgress = 0,
  });

  final int completedSteps;
  final int totalSteps;
  final String currentStepLabel;
  final double currentStepProgress;

  double get value {
    if (totalSteps <= 0) {
      return 0;
    }
    final normalizedStep = currentStepProgress.clamp(0.0, 1.0);
    final progress = (completedSteps + normalizedStep) / totalSteps;
    return progress.clamp(0.0, 1.0).toDouble();
  }

  int get percent => (value * 100).round().clamp(0, 100);

  int get currentStep {
    if (totalSteps <= 0) {
      return 0;
    }
    return (completedSteps + 1).clamp(1, totalSteps);
  }

  String get stepLabel => 'Step $currentStep of $totalSteps';
}

class BuildPreviewVideoResult {
  const BuildPreviewVideoResult({
    required this.outputPath,
    required this.signature,
    required this.totalDuration,
    required this.thumbnails,
  });

  final String outputPath;
  final String signature;
  final Duration totalDuration;
  final List<PreviewImageFrame> thumbnails;
}

class PreviewImageFrame {
  const PreviewImageFrame({required this.clipId, required this.bytes});

  final String clipId;
  final Uint8List bytes;
}
