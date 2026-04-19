import 'package:picturestovideos/core/audio/domain/beat.dart';

class BeatMap {
  const BeatMap({
    required this.beats,
    required this.bpm,
    required this.averageBeatInterval,
  });

  final List<Beat> beats;
  final double bpm;
  final Duration averageBeatInterval;
}
