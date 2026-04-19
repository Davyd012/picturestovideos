import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioPlayerRepositoryProvider = Provider<AudioPlayerRepository>(
  (ref) => ManualAudioPlayerRepository(),
);

abstract interface class AudioPlayerRepository {
  Stream<Duration> get positionStream;

  Duration get currentPosition;

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> step(Duration delta);
}

class ManualAudioPlayerRepository implements AudioPlayerRepository {
  ManualAudioPlayerRepository()
      : _controller = StreamController<Duration>.broadcast();

  final StreamController<Duration> _controller;
  Duration _currentPosition = Duration.zero;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Stream<Duration> get positionStream => _controller.stream;

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
    _currentPosition =
        Duration(microseconds: nextMicros < 0 ? 0 : nextMicros);
    _controller.add(_currentPosition);
  }
}
