import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';

class PlaybackState {
  const PlaybackState({
    required this.beatMap,
    required this.currentTime,
    required this.nextBeatIndex,
    required this.triggeredBeats,
    required this.isPlaying,
  });

  const PlaybackState.initial()
      : beatMap = const BeatMap(
          beats: [],
          bpm: 0,
          averageBeatInterval: Duration.zero,
        ),
        currentTime = Duration.zero,
        nextBeatIndex = 0,
        triggeredBeats = const [],
        isPlaying = false;

  final BeatMap beatMap;
  final Duration currentTime;
  final int nextBeatIndex;
  final List<Beat> triggeredBeats;
  final bool isPlaying;

  bool get hasBeatMap => beatMap.beats.isNotEmpty;

  Beat? get lastTriggeredBeat =>
      triggeredBeats.isEmpty ? null : triggeredBeats.last;

  PlaybackState copyWith({
    BeatMap? beatMap,
    Duration? currentTime,
    int? nextBeatIndex,
    List<Beat>? triggeredBeats,
    bool? isPlaying,
  }) {
    return PlaybackState(
      beatMap: beatMap ?? this.beatMap,
      currentTime: currentTime ?? this.currentTime,
      nextBeatIndex: nextBeatIndex ?? this.nextBeatIndex,
      triggeredBeats: triggeredBeats ?? this.triggeredBeats,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
