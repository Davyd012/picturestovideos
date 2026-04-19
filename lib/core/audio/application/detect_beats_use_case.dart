import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';

final detectBeatsUseCaseProvider = Provider<DetectBeatsUseCase>(
  (ref) => DetectBeatsUseCase(
    beatDetector: ref.watch(beatDetectorProvider),
  ),
);

class DetectBeatsUseCase {
  const DetectBeatsUseCase({
    required BeatDetector beatDetector,
  }) : this._(beatDetector);

  const DetectBeatsUseCase._(this._beatDetector);

  final BeatDetector _beatDetector;

  List<Beat> call({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) {
    return _beatDetector.detect(
      frames: frames,
      config: config,
    );
  }
}
