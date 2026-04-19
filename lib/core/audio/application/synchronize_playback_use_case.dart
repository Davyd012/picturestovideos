import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/playback_coordinator.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/playback_sync_result.dart';

final synchronizePlaybackUseCaseProvider = Provider<SynchronizePlaybackUseCase>(
  (ref) => SynchronizePlaybackUseCase(
    playbackCoordinator: ref.watch(playbackCoordinatorProvider),
  ),
);

class SynchronizePlaybackUseCase {
  const SynchronizePlaybackUseCase({
    required PlaybackCoordinator playbackCoordinator,
  }) : this._(playbackCoordinator);

  const SynchronizePlaybackUseCase._(this._playbackCoordinator);

  final PlaybackCoordinator _playbackCoordinator;

  PlaybackSyncResult call({
    required BeatMap beatMap,
    required Duration currentTime,
    required int nextBeatIndex,
    Duration tolerance = const Duration(milliseconds: 40),
  }) {
    return _playbackCoordinator.synchronize(
      beatMap: beatMap,
      currentTime: currentTime,
      nextBeatIndex: nextBeatIndex,
      tolerance: tolerance,
    );
  }
}
