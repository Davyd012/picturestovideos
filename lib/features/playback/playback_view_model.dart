import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/synchronize_playback_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';

final playbackViewModelProvider =
    AsyncNotifierProvider.autoDispose<PlaybackViewModel, PlaybackState>(
  PlaybackViewModel.new,
);

class PlaybackViewModel extends AsyncNotifier<PlaybackState> {
  StreamSubscription<Duration>? _positionSubscription;

  @override
  Future<PlaybackState> build() async {
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });

    _positionSubscription ??=
        ref.read(audioPlayerRepositoryProvider).positionStream.listen(
      _handlePositionChanged,
    );

    return const PlaybackState.initial();
  }

  Future<void> loadBeatMap(BeatMap beatMap) async {
    final repository = ref.read(audioPlayerRepositoryProvider);
    await repository.seek(Duration.zero);

    final previousState = state.value ?? const PlaybackState.initial();
    state = AsyncData(
      previousState.copyWith(
        beatMap: beatMap,
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
      ),
    );
  }

  Future<void> play() async {
    final previousState = state.value ?? const PlaybackState.initial();
    await ref.read(audioPlayerRepositoryProvider).play();
    state = AsyncData(previousState.copyWith(isPlaying: true));
  }

  Future<void> pause() async {
    final previousState = state.value ?? const PlaybackState.initial();
    await ref.read(audioPlayerRepositoryProvider).pause();
    state = AsyncData(previousState.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    await ref.read(audioPlayerRepositoryProvider).seek(position);
  }

  Future<void> step(Duration delta) async {
    await ref.read(audioPlayerRepositoryProvider).step(delta);
  }

  void _handlePositionChanged(Duration currentTime) {
    final previousState = state.value ?? const PlaybackState.initial();
    if (!previousState.hasBeatMap) {
      state = AsyncData(previousState.copyWith(currentTime: currentTime));
      return;
    }

    final syncResult = ref.read(synchronizePlaybackUseCaseProvider).call(
          beatMap: previousState.beatMap,
          currentTime: currentTime,
          nextBeatIndex: previousState.nextBeatIndex,
        );

    state = AsyncData(
      previousState.copyWith(
        currentTime: currentTime,
        nextBeatIndex: syncResult.nextBeatIndex,
        triggeredBeats: [
          ...previousState.triggeredBeats,
          ...syncResult.triggeredBeats,
        ],
      ),
    );
  }
}
