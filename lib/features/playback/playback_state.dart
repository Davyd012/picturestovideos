import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';

class PlaybackState {
  const PlaybackState({
    required this.beatMap,
    required this.currentTime,
    required this.nextBeatIndex,
    required this.triggeredBeats,
    required this.isPlaying,
    required this.isCompleted,
    this.audioSourcePath,
    this.sourceDuration,
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
      isPlaying = false,
      isCompleted = false,
      audioSourcePath = null,
      sourceDuration = null;

  final BeatMap beatMap;
  final Duration currentTime;
  final int nextBeatIndex;
  final List<Beat> triggeredBeats;
  final bool isPlaying;
  final bool isCompleted;
  final String? audioSourcePath;
  final Duration? sourceDuration;

  bool get hasBeatMap => beatMap.beats.isNotEmpty;
  bool get hasLoadedAudioSource =>
      audioSourcePath != null && audioSourcePath!.isNotEmpty;

  Beat? get lastTriggeredBeat =>
      triggeredBeats.isEmpty ? null : triggeredBeats.last;

  PlaybackState copyWith({
    BeatMap? beatMap,
    Duration? currentTime,
    int? nextBeatIndex,
    List<Beat>? triggeredBeats,
    bool? isPlaying,
    bool? isCompleted,
    String? audioSourcePath,
    Duration? sourceDuration,
  }) {
    return PlaybackState(
      beatMap: beatMap ?? this.beatMap,
      currentTime: currentTime ?? this.currentTime,
      nextBeatIndex: nextBeatIndex ?? this.nextBeatIndex,
      triggeredBeats: triggeredBeats ?? this.triggeredBeats,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      audioSourcePath: audioSourcePath ?? this.audioSourcePath,
      sourceDuration: sourceDuration ?? this.sourceDuration,
    );
  }
}
