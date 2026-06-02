import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

final audioPlayerRepositoryProvider = Provider<AudioPlayerRepository>((ref) {
  final repository = AppAudioPlayerRepository(
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(() {
    repository.dispose();
  });
  return repository;
});

abstract interface class AudioPlayerRepository {
  Stream<Duration> get positionStream;

  Duration get currentPosition;

  bool get hasLoadedSource;

  Future<void> load(String? audioSourcePath);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> step(Duration delta);

  Future<void> dispose();
}

class AppAudioPlayerRepository implements AudioPlayerRepository {
  static const _loadTimeout = Duration(seconds: 8);

  AppAudioPlayerRepository({required this._logger}) {
    _positionSubscription = _player.onPositionChanged.listen((position) {
      _currentPosition = position;
      _controller.add(position);
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      _currentPosition = Duration.zero;
      _controller.add(_currentPosition);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<Duration> _controller =
      StreamController<Duration>.broadcast();
  final AppLogger _logger;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completeSubscription;
  Duration _currentPosition = Duration.zero;
  String? _loadedSourcePath;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  bool get hasLoadedSource =>
      _loadedSourcePath != null && _loadedSourcePath!.isNotEmpty;

  @override
  Stream<Duration> get positionStream => _controller.stream;

  @override
  Future<void> load(String? audioSourcePath) async {
    if (audioSourcePath == null || audioSourcePath.isEmpty) {
      _loadedSourcePath = null;
      _logger.warning(
        'AudioPlayerRepository',
        'No audio source path available for playback',
      );
      return;
    }

    if (_loadedSourcePath == audioSourcePath) {
      _logger.debug(
        'AudioPlayerRepository',
        'Audio source already loaded: $audioSourcePath',
      );
      return;
    }

    await _player.stop();
    try {
      await _player
          .setSource(DeviceFileSource(audioSourcePath))
          .timeout(_loadTimeout);
    } on TimeoutException catch (error, stackTrace) {
      _loadedSourcePath = null;
      _logger.error(
        'AudioPlayerRepository',
        error,
        stackTrace,
        message:
            'Audio player timed out while loading source $audioSourcePath',
      );
      throw TimeoutException(
        'Audio playback could not be prepared from this file path. You can still edit the timeline, but playback controls may stay unavailable until audio loading succeeds.',
        _loadTimeout,
      );
    }
    _loadedSourcePath = audioSourcePath;
    _currentPosition = Duration.zero;
    _controller.add(_currentPosition);
    _logger.info(
      'AudioPlayerRepository',
      'Loaded audio source $audioSourcePath',
    );
  }

  @override
  Future<void> pause() async {
    _logger.info('AudioPlayerRepository', 'Pausing audio playback');
    await _player.pause();
  }

  @override
  Future<void> play() async {
    if (!hasLoadedSource) {
      _logger.warning(
        'AudioPlayerRepository',
        'Play requested without a loaded audio source',
      );
      return;
    }

    _logger.info('AudioPlayerRepository', 'Starting audio playback');
    await _player.resume();
  }

  @override
  Future<void> seek(Duration position) async {
    _logger.debug(
      'AudioPlayerRepository',
      'Seeking to ${position.inMilliseconds} ms',
    );
    _currentPosition = position;
    await _player.seek(position);
    _controller.add(_currentPosition);
  }

  @override
  Future<void> step(Duration delta) async {
    final nextMicros = _currentPosition.inMicroseconds + delta.inMicroseconds;
    final nextPosition = Duration(
      microseconds: nextMicros < 0 ? 0 : nextMicros,
    );
    await seek(nextPosition);
  }

  @override
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _completeSubscription?.cancel();
    await _controller.close();
    await _player.dispose();
  }
}

class ManualAudioPlayerRepository implements AudioPlayerRepository {
  ManualAudioPlayerRepository()
    : _controller = StreamController<Duration>.broadcast();

  final StreamController<Duration> _controller;
  Duration _currentPosition = Duration.zero;
  String? _loadedSourcePath;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  bool get hasLoadedSource =>
      _loadedSourcePath != null && _loadedSourcePath!.isNotEmpty;

  @override
  Stream<Duration> get positionStream => _controller.stream;

  @override
  Future<void> load(String? audioSourcePath) async {
    _loadedSourcePath = audioSourcePath;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    _controller.add(_currentPosition);
  }

  @override
  Future<void> step(Duration delta) async {
    final nextMicros = _currentPosition.inMicroseconds + delta.inMicroseconds;
    _currentPosition = Duration(microseconds: nextMicros < 0 ? 0 : nextMicros);
    _controller.add(_currentPosition);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
