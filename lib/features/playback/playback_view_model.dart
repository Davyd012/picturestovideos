import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/synchronize_playback_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';

final playbackViewModelProvider =
    AsyncNotifierProvider<PlaybackViewModel, PlaybackState>(
      PlaybackViewModel.new,
    );

class PlaybackViewModel extends AsyncNotifier<PlaybackState> {
  static const _tag = 'PlaybackViewModel';

  StreamSubscription<Duration>? _positionSubscription;

  @override
  Future<PlaybackState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing playback state');
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });

    _positionSubscription ??= ref
        .read(audioPlayerRepositoryProvider)
        .positionStream
        .listen(_handlePositionChanged);

    return const PlaybackState.initial();
  }

  Future<void> loadBeatMap(BeatMap beatMap, {String? audioSourcePath}) async {
    await preparePlayback(beatMap: beatMap, audioSourcePath: audioSourcePath);
  }

  Future<void> preparePlayback({
    required BeatMap beatMap,
    String? audioSourcePath,
  }) async {
    final logger = ref.read(appLoggerProvider);
    final repository = ref.read(audioPlayerRepositoryProvider);
    final previousState = state.value ?? const PlaybackState.initial();
    final shouldReloadSession =
        !previousState.hasBeatMap ||
        !previousState.hasLoadedAudioSource ||
        previousState.audioSourcePath != audioSourcePath ||
        previousState.beatMap.beats.length != beatMap.beats.length ||
        previousState.beatMap.bpm != beatMap.bpm ||
        previousState.beatMap.averageBeatInterval !=
            beatMap.averageBeatInterval;

    if (!shouldReloadSession) {
      logger.debug(_tag, 'Playback session already ready');
      return;
    }

    logger.info(_tag, 'Preparing playback with ${beatMap.beats.length} beats');
    await repository.load(audioSourcePath);
    await repository.seek(Duration.zero);

    state = AsyncData(
      previousState.copyWith(
        beatMap: beatMap,
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
        audioSourcePath: audioSourcePath,
      ),
    );
  }

  Future<void> play() async {
    final logger = ref.read(appLoggerProvider);
    final previousState = state.value ?? const PlaybackState.initial();
    if (!previousState.hasLoadedAudioSource) {
      logger.warning(_tag, 'Play ignored because no audio source is loaded');
      return;
    }

    await ref.read(audioPlayerRepositoryProvider).play();
    logger.info(_tag, 'Playback started');
    state = AsyncData(previousState.copyWith(isPlaying: true));
  }

  Future<void> pause() async {
    ref.read(appLoggerProvider).info(_tag, 'Playback paused');
    final previousState = state.value ?? const PlaybackState.initial();
    await ref.read(audioPlayerRepositoryProvider).pause();
    state = AsyncData(previousState.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    ref
        .read(appLoggerProvider)
        .debug(_tag, 'Seeking to ${position.inMilliseconds} ms');
    await ref.read(audioPlayerRepositoryProvider).seek(position);
  }

  Future<void> step(Duration delta) async {
    ref
        .read(appLoggerProvider)
        .debug(_tag, 'Stepping by ${delta.inMilliseconds} ms');
    await ref.read(audioPlayerRepositoryProvider).step(delta);
  }

  Future<void> reset() async {
    final repository = ref.read(audioPlayerRepositoryProvider);
    if (repository.hasLoadedSource) {
      await repository.pause();
      await repository.seek(Duration.zero);
    }
    state = const AsyncData(PlaybackState.initial());
  }

  void _handlePositionChanged(Duration currentTime) {
    final previousState = state.value ?? const PlaybackState.initial();
    if (!previousState.hasBeatMap) {
      state = AsyncData(previousState.copyWith(currentTime: currentTime));
      return;
    }

    final didSeekBackward = currentTime < previousState.currentTime;
    final syncResult = ref
        .read(synchronizePlaybackUseCaseProvider)
        .call(
          beatMap: previousState.beatMap,
          currentTime: currentTime,
          nextBeatIndex: didSeekBackward ? 0 : previousState.nextBeatIndex,
        );
    final triggeredBeats = didSeekBackward
        ? syncResult.triggeredBeats
        : [...previousState.triggeredBeats, ...syncResult.triggeredBeats];

    state = AsyncData(
      previousState.copyWith(
        currentTime: currentTime,
        nextBeatIndex: syncResult.nextBeatIndex,
        triggeredBeats: List.unmodifiable(triggeredBeats),
      ),
    );
  }
}
