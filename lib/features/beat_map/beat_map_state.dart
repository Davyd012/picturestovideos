import 'package:picturestovideos/core/audio/domain/beat_map.dart';

class BeatMapState {
  const BeatMapState({
    required this.beatMap,
  });

  const BeatMapState.initial()
      : beatMap = const BeatMap(
          beats: [],
          bpm: 0,
          averageBeatInterval: Duration.zero,
        );

  final BeatMap beatMap;

  bool get hasBeatMap => beatMap.beats.isNotEmpty;
}
