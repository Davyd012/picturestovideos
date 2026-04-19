import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';

class BeatDetectionState {
  const BeatDetectionState({
    required this.config,
    required this.beats,
  });

  const BeatDetectionState.initial()
      : config = const BeatDetectionConfig.defaults(),
        beats = const [];

  final BeatDetectionConfig config;
  final List<Beat> beats;

  int get beatCount => beats.length;

  Beat? get firstBeat => beats.isEmpty ? null : beats.first;

  Beat? get lastBeat => beats.isEmpty ? null : beats.last;
}
