import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_processing_task.dart';

final detectBeatsUseCaseProvider = Provider<DetectBeatsUseCase>(
  (ref) => DetectBeatsUseCase(beatDetector: ref.watch(beatDetectorProvider)),
);

class DetectBeatsUseCase {
  const DetectBeatsUseCase({required BeatDetector beatDetector})
    : this._(beatDetector);

  const DetectBeatsUseCase._(this._beatDetector);

  final BeatDetector _beatDetector;

  Future<List<Beat>> call({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) async {
    final result = await compute(
      _detectBeatsOnIsolate,
      DetectBeatsRequest(frames: frames, config: config),
    );

    return result.beats;
  }
}

DetectBeatsResult _detectBeatsOnIsolate(DetectBeatsRequest request) {
  final beats = const BeatDetector().detect(
    frames: request.frames,
    config: request.config,
  );
  return DetectBeatsResult(beats: beats);
}
