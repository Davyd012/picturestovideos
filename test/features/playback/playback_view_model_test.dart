import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/playback_coordinator.dart';
import 'package:picturestovideos/core/audio/application/synchronize_playback_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/playback_sync_result.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';

void main() {
  test('step updates playback time and triggered beats', () async {
    final repository = ManualAudioPlayerRepository();
    final container = ProviderContainer(
      overrides: [
        audioPlayerRepositoryProvider.overrideWithValue(repository),
        synchronizePlaybackUseCaseProvider.overrideWithValue(
          _FakeSynchronizePlaybackUseCase(
            results: const [
              PlaybackSyncResult(
                triggeredBeats: [],
                nextBeatIndex: 0,
              ),
              PlaybackSyncResult(
                triggeredBeats: [
                  Beat(
                    time: Duration(milliseconds: 200),
                    strength: 1.6,
                  ),
                ],
                nextBeatIndex: 1,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(playbackViewModelProvider.future);
    await container.read(playbackViewModelProvider.notifier).loadBeatMap(
          const BeatMap(
            beats: [
              Beat(
                time: Duration(milliseconds: 200),
                strength: 1.6,
              ),
            ],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
        );
    await container.read(playbackViewModelProvider.notifier).step(
          const Duration(milliseconds: 100),
        );
    await container.read(playbackViewModelProvider.notifier).step(
          const Duration(milliseconds: 100),
        );

    final state = container.read(playbackViewModelProvider);

    expect(state, isA<AsyncData<PlaybackState>>());
    expect(state.value?.currentTime, const Duration(milliseconds: 200));
    expect(state.value?.triggeredBeats.length, 1);
    expect(state.value?.nextBeatIndex, 1);
  });
}

class _FakeSynchronizePlaybackUseCase extends SynchronizePlaybackUseCase {
  _FakeSynchronizePlaybackUseCase({
    required this.results,
  }) : super(playbackCoordinator: const PlaybackCoordinator());

  final List<PlaybackSyncResult> results;
  int _callCount = 0;

  @override
  PlaybackSyncResult call({
    required BeatMap beatMap,
    required Duration currentTime,
    required int nextBeatIndex,
    Duration tolerance = const Duration(milliseconds: 40),
  }) {
    final index = _callCount < results.length ? _callCount : results.length - 1;
    _callCount += 1;
    return results[index];
  }
}
