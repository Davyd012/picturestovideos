import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/synchronize_playback_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';

final playbackViewModelProvider =
    AsyncNotifierProvider<PlaybackViewModel, PlaybackState>(
      PlaybackViewModel.new,
    );

class PlaybackViewModel extends AsyncNotifier<PlaybackState> {
  static const _tag = 'PlaybackViewModel';

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completeSubscription;
  AudioMix _mix = const AudioMix();
  Duration? _videoDuration;
  Duration? _sourceDuration;
  Timer? _silenceTimer;
  Stopwatch? _silenceClock;
  Duration _silenceStart = Duration.zero;
  bool _inSilentRange = false;

  @override
  Future<PlaybackState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing playback state');
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _completeSubscription?.cancel();
      _stopSilence();
    });

    final repository = ref.read(audioPlayerRepositoryProvider);
    _positionSubscription ??= repository.positionStream.listen(
      _handlePositionChanged,
    );
    _completeSubscription ??= repository.completeStream.listen(
      (_) => _handlePlaybackCompleted(),
    );

    return const PlaybackState.initial();
  }

  Future<void> loadBeatMap(BeatMap beatMap, {String? audioSourcePath}) async {
    await preparePlayback(beatMap: beatMap, audioSourcePath: audioSourcePath);
  }

  Future<void> preparePlayback({
    required BeatMap beatMap,
    String? audioSourcePath,
    AudioMix audioMix = const AudioMix(),
    Duration? videoDuration,
  }) async {
    final logger = ref.read(appLoggerProvider);
    final repository = ref.read(audioPlayerRepositoryProvider);
    final visibleBeats = [
      for (final beat in beatMap.beats)
        if (!beat.time.isNegative &&
            (videoDuration == null || beat.time <= videoDuration))
          beat,
    ];
    final visibleBeatMap = visibleBeats.length == beatMap.beats.length
        ? beatMap
        : BeatMap(
            beats: visibleBeats,
            bpm: beatMap.bpm,
            averageBeatInterval: beatMap.averageBeatInterval,
          );
    final previousState = state.value ?? const PlaybackState.initial();
    final shouldLoadAudioSource =
        (audioSourcePath?.isNotEmpty ?? false) && !repository.hasLoadedSource;
    final shouldReloadSession =
        shouldLoadAudioSource ||
        previousState.isCompleted ||
        repository.isCompleted ||
        previousState.audioSourcePath != audioSourcePath ||
        previousState.beatMap.beats.length != visibleBeatMap.beats.length ||
        previousState.beatMap.bpm != visibleBeatMap.bpm ||
        previousState.beatMap.averageBeatInterval !=
            beatMap.averageBeatInterval ||
        _mix != audioMix ||
        _videoDuration != videoDuration;

    if (!shouldReloadSession) {
      logger.debug(_tag, 'Playback session already ready');
      return;
    }

    logger.info(_tag, 'Preparing playback with ${beatMap.beats.length} beats');
    _stopSilence();
    _inSilentRange = false;
    if (repository.hasLoadedSource) await repository.pause();
    await repository.load(audioSourcePath);
    _mix = audioMix;
    _videoDuration = videoDuration;
    _sourceDuration = repository.sourceDuration;
    await repository.setVolume(_volumeAt(Duration.zero));
    await repository.seek(_mix.start);

    state = AsyncData(
      previousState.copyWith(
        beatMap: visibleBeatMap,
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
        isCompleted: false,
        audioSourcePath: audioSourcePath,
        sourceDuration: _timelineDuration,
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

    final audible = _audibleDuration;
    if (!previousState.isCompleted &&
        audible != null &&
        _videoDuration != null &&
        previousState.currentTime >= audible &&
        previousState.currentTime < _videoDuration!) {
      _startSilence(previousState.currentTime);
      return;
    }
    if (previousState.isCompleted ||
        ref.read(audioPlayerRepositoryProvider).isCompleted) {
      await _recoverCompletedSession(previousState);
    }
    final nextState = state.value ?? previousState;
    _inSilentRange = false;
    await ref
        .read(audioPlayerRepositoryProvider)
        .setVolume(_volumeAt(nextState.currentTime));
    await ref.read(audioPlayerRepositoryProvider).play();
    logger.info(_tag, 'Playback started');
    state = AsyncData(nextState.copyWith(isPlaying: true, isCompleted: false));
  }

  Future<void> pause() async {
    ref.read(appLoggerProvider).info(_tag, 'Playback paused');
    final previousState = state.value ?? const PlaybackState.initial();
    _stopSilence();
    await ref.read(audioPlayerRepositoryProvider).pause();
    state = AsyncData(previousState.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    ref
        .read(appLoggerProvider)
        .debug(_tag, 'Seeking to ${position.inMilliseconds} ms');
    final previousState = state.value ?? const PlaybackState.initial();
    final limit = _timelineDuration;
    final safe = position < Duration.zero
        ? Duration.zero
        : limit != null && position > limit
        ? limit
        : position;
    _stopSilence();
    final audible = _audibleDuration;
    _inSilentRange =
        audible != null &&
        safe >= audible &&
        _videoDuration != null &&
        _videoDuration! > audible;
    final sourcePosition = audible != null && safe > audible ? audible : safe;
    await ref.read(audioPlayerRepositoryProvider).pause();
    await ref.read(audioPlayerRepositoryProvider).setVolume(_volumeAt(safe));
    await ref
        .read(audioPlayerRepositoryProvider)
        .seek(_mix.start + sourcePosition);
    state = AsyncData(
      previousState.copyWith(
        currentTime: safe,
        isPlaying: false,
        isCompleted: limit != null && safe >= limit,
      ),
    );
  }

  Future<void> restart() async {
    final previousState = state.value ?? const PlaybackState.initial();
    final repository = ref.read(audioPlayerRepositoryProvider);
    _stopSilence();
    _inSilentRange = false;
    if (!repository.hasLoadedSource) {
      return;
    }

    await repository.pause();
    if (previousState.isCompleted || repository.isCompleted) {
      await repository.reload();
    } else {
      await repository.seek(_mix.start);
    }
    if (previousState.isCompleted || repository.isCompleted) {
      await repository.seek(_mix.start);
    }
    await repository.setVolume(_volumeAt(Duration.zero));
    state = AsyncData(
      previousState.copyWith(
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
        isCompleted: false,
      ),
    );
  }

  Future<void> step(Duration delta) async {
    ref
        .read(appLoggerProvider)
        .debug(_tag, 'Stepping by ${delta.inMilliseconds} ms');
    final previousState = state.value ?? const PlaybackState.initial();
    final repository = ref.read(audioPlayerRepositoryProvider);
    if (!_inSilentRange &&
        (previousState.isCompleted || repository.isCompleted)) {
      await _recoverCompletedSession(previousState);
    }
    final target = (state.value ?? previousState).currentTime + delta;
    final limit = _timelineDuration;
    final safe = target < Duration.zero
        ? Duration.zero
        : limit != null && target > limit
        ? limit
        : target;
    final audible = _audibleDuration;
    if (_inSilentRange ||
        audible != null &&
            safe >= audible &&
            _videoDuration != null &&
            _videoDuration! > audible) {
      await seek(safe);
    } else {
      _inSilentRange = false;
      await repository.seek(_mix.start + safe);
    }
  }

  Future<void> reset() async {
    _stopSilence();
    _inSilentRange = false;
    final repository = ref.read(audioPlayerRepositoryProvider);
    if (repository.hasLoadedSource) {
      await repository.pause();
      await repository.seek(Duration.zero);
    }
    state = const AsyncData(PlaybackState.initial());
    _mix = const AudioMix();
    _sourceDuration = null;
    _videoDuration = null;
  }

  Duration? get _audibleDuration {
    final bound = _videoDuration ?? _sourceDuration;
    if (bound == null) return null;
    return _mix.effectiveDuration(
      sourceDuration: _sourceDuration,
      videoDuration: bound,
    );
  }

  Duration? get _timelineDuration => _videoDuration ?? _audibleDuration;

  void _stopSilence() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _silenceClock?.stop();
    _silenceClock = null;
  }

  void _startSilence(Duration start) {
    _stopSilence();
    _inSilentRange = true;
    _silenceStart = start;
    _silenceClock = Stopwatch()..start();
    final previous = state.value ?? const PlaybackState.initial();
    state = AsyncData(
      previous.copyWith(
        currentTime: start,
        isPlaying: true,
        isCompleted: false,
      ),
    );
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final limit = _videoDuration;
      if (limit == null) return;
      final time = _silenceStart + _silenceClock!.elapsed;
      final current = state.value ?? const PlaybackState.initial();
      if (time >= limit) {
        _stopSilence();
        state = AsyncData(
          current.copyWith(
            currentTime: limit,
            isPlaying: false,
            isCompleted: true,
          ),
        );
      } else {
        state = AsyncData(current.copyWith(currentTime: time));
      }
    });
  }

  double _volumeAt(Duration position) {
    final bound = _videoDuration ?? _sourceDuration;
    if (bound == null) return 1;
    return _mix.volumeAt(
      position,
      sourceDuration: _sourceDuration,
      videoDuration: bound,
    );
  }

  void _handlePositionChanged(Duration sourceTime) {
    if (_inSilentRange) return;
    final previousState = state.value ?? const PlaybackState.initial();
    final rawTime = sourceTime - _mix.start;
    final currentTime = rawTime.isNegative ? Duration.zero : rawTime;
    final limit = _audibleDuration;
    unawaited(
      ref
          .read(audioPlayerRepositoryProvider)
          .setVolume(_volumeAt(currentTime))
          .catchError((Object error, StackTrace stackTrace) {
            ref
                .read(appLoggerProvider)
                .error(
                  _tag,
                  error,
                  stackTrace,
                  message: 'Could not update playback volume',
                );
          }),
    );
    if (limit != null && currentTime >= limit && previousState.isPlaying) {
      unawaited(
        ref.read(audioPlayerRepositoryProvider).pause().catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          ref
              .read(appLoggerProvider)
              .error(
                _tag,
                error,
                stackTrace,
                message: 'Could not stop playback at the music boundary',
              );
        }),
      );
      if (_videoDuration != null && _videoDuration! > limit) {
        _startSilence(limit);
      } else {
        state = AsyncData(
          previousState.copyWith(
            currentTime: limit,
            isPlaying: false,
            isCompleted: true,
          ),
        );
      }
      return;
    }
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
        isCompleted: false,
      ),
    );
  }

  void _handlePlaybackCompleted() {
    if (_inSilentRange) return;
    final previousState = state.value ?? const PlaybackState.initial();
    final audible = _audibleDuration;
    if (previousState.isPlaying &&
        audible != null &&
        _videoDuration != null &&
        _videoDuration! > audible) {
      _startSilence(audible);
      return;
    }
    state = AsyncData(
      previousState.copyWith(
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
        isCompleted: true,
      ),
    );
  }

  Future<void> _recoverCompletedSession(PlaybackState previousState) async {
    final repository = ref.read(audioPlayerRepositoryProvider);
    if (!repository.hasLoadedSource) {
      return;
    }

    await repository.reload();
    await repository.seek(_mix.start);
    await repository.setVolume(_volumeAt(Duration.zero));
    state = AsyncData(
      previousState.copyWith(
        currentTime: Duration.zero,
        nextBeatIndex: 0,
        triggeredBeats: const [],
        isPlaying: false,
        isCompleted: false,
      ),
    );
  }
}
