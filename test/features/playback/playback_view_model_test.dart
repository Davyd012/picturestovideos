import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/playback_coordinator.dart';
import 'package:picturestovideos/core/audio/application/synchronize_playback_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/playback_sync_result.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';

void main() {
  test(
    'preview continues through silence when music ends before video',
    () async {
      final repository = ManualAudioPlayerRepository()
        ..setSourceDuration(const Duration(milliseconds: 100));
      final container = ProviderContainer(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(repository.dispose);
      addTearDown(container.dispose);
      await container.read(playbackViewModelProvider.future);
      final vm = container.read(playbackViewModelProvider.notifier);
      await vm.preparePlayback(
        beatMap: const BeatMap(
          beats: [],
          bpm: 0,
          averageBeatInterval: Duration.zero,
        ),
        audioSourcePath: 'short.wav',
        videoDuration: const Duration(milliseconds: 400),
      );
      await vm.play();
      repository.complete();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final playing = container.read(playbackViewModelProvider).value!;
      expect(playing.isPlaying, isTrue);
      expect(
        playing.currentTime,
        greaterThan(const Duration(milliseconds: 100)),
      );
      await vm.pause();
      expect(
        container.read(playbackViewModelProvider).value!.isPlaying,
        isFalse,
      );
    },
  );
  test(
    'trimmed playback seeks in source time and applies fades in video time',
    () async {
      final repository = ManualAudioPlayerRepository()
        ..setSourceDuration(const Duration(seconds: 10));
      final container = ProviderContainer(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);
      await container.read(playbackViewModelProvider.future);
      final vm = container.read(playbackViewModelProvider.notifier);
      await vm.preparePlayback(
        beatMap: const BeatMap(
          beats: [],
          bpm: 0,
          averageBeatInterval: Duration.zero,
        ),
        audioSourcePath: 'music.wav',
        audioMix: const AudioMix(
          start: Duration(seconds: 2),
          end: Duration(seconds: 6),
          fadeIn: Duration(seconds: 1),
          fadeOut: Duration(seconds: 1),
        ),
        videoDuration: const Duration(seconds: 4),
      );
      expect(repository.currentPosition, const Duration(seconds: 2));
      expect(repository.volume, 0);
      await vm.seek(const Duration(milliseconds: 500));
      expect(repository.currentPosition, const Duration(milliseconds: 2500));
      expect(repository.volume, closeTo(0.5, 0.001));
      await vm.seek(const Duration(milliseconds: 3500));
      expect(repository.currentPosition, const Duration(milliseconds: 5500));
      expect(repository.volume, closeTo(0.5, 0.001));
      await vm.restart();
      expect(repository.currentPosition, const Duration(seconds: 2));
    },
  );
  test('preparePlayback exposes loaded source duration', () async {
    final repository = ManualAudioPlayerRepository()
      ..setSourceDuration(const Duration(minutes: 3, seconds: 42));
    final container = ProviderContainer(
      overrides: [audioPlayerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(playbackViewModelProvider.future);
    await container
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap: const BeatMap(
            beats: [],
            bpm: 0,
            averageBeatInterval: Duration(seconds: 2),
          ),
          audioSourcePath: '/tmp/song.mp3',
        );

    expect(
      container.read(playbackViewModelProvider).value?.sourceDuration,
      const Duration(minutes: 3, seconds: 42),
    );
  });

  test(
    'empty beat map preserves the current position between transport actions',
    () async {
      final repository = ManualAudioPlayerRepository();
      final container = ProviderContainer(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      const beatMap = BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration.zero,
      );

      await container.read(playbackViewModelProvider.future);
      await container
          .read(playbackViewModelProvider.notifier)
          .preparePlayback(beatMap: beatMap, audioSourcePath: '/tmp/song.wav');
      await container
          .read(playbackViewModelProvider.notifier)
          .step(const Duration(seconds: 15));

      await container
          .read(playbackViewModelProvider.notifier)
          .preparePlayback(beatMap: beatMap, audioSourcePath: '/tmp/song.wav');
      await container
          .read(playbackViewModelProvider.notifier)
          .step(const Duration(seconds: 10));

      final state = container.read(playbackViewModelProvider).value;
      expect(repository.loadCount, 1);
      expect(repository.currentPosition, const Duration(seconds: 25));
      expect(state?.currentTime, const Duration(seconds: 25));
    },
  );

  test('step updates playback time and triggered beats', () async {
    final repository = ManualAudioPlayerRepository();
    final container = ProviderContainer(
      overrides: [
        audioPlayerRepositoryProvider.overrideWithValue(repository),
        synchronizePlaybackUseCaseProvider.overrideWithValue(
          _FakeSynchronizePlaybackUseCase(
            results: const [
              PlaybackSyncResult(triggeredBeats: [], nextBeatIndex: 0),
              PlaybackSyncResult(
                triggeredBeats: [
                  Beat(time: Duration(milliseconds: 200), strength: 1.6),
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
    await container
        .read(playbackViewModelProvider.notifier)
        .loadBeatMap(
          const BeatMap(
            beats: [Beat(time: Duration(milliseconds: 200), strength: 1.6)],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
        );
    await container
        .read(playbackViewModelProvider.notifier)
        .step(const Duration(milliseconds: 100));
    await container
        .read(playbackViewModelProvider.notifier)
        .step(const Duration(milliseconds: 100));

    final state = container.read(playbackViewModelProvider);

    expect(state, isA<AsyncData<PlaybackState>>());
    expect(state.value?.currentTime, const Duration(milliseconds: 200));
    expect(state.value?.triggeredBeats.length, 1);
    expect(state.value?.nextBeatIndex, 1);
  });

  test(
    'restart seeks to beginning without clearing loaded playback data',
    () async {
      final repository = ManualAudioPlayerRepository();
      final container = ProviderContainer(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      const beatMap = BeatMap(
        beats: [Beat(time: Duration(milliseconds: 200), strength: 1.6)],
        bpm: 120,
        averageBeatInterval: Duration(milliseconds: 500),
      );

      await container.read(playbackViewModelProvider.future);
      await container
          .read(playbackViewModelProvider.notifier)
          .preparePlayback(beatMap: beatMap, audioSourcePath: '/tmp/song.wav');
      await container
          .read(playbackViewModelProvider.notifier)
          .step(const Duration(seconds: 2));
      await container.read(playbackViewModelProvider.notifier).play();

      await container.read(playbackViewModelProvider.notifier).restart();

      final state = container.read(playbackViewModelProvider).value;
      expect(repository.currentPosition, Duration.zero);
      expect(repository.isPlaying, isFalse);
      expect(state?.currentTime, Duration.zero);
      expect(state?.nextBeatIndex, 0);
      expect(state?.triggeredBeats, isEmpty);
      expect(state?.isPlaying, isFalse);
      expect(state?.isCompleted, isFalse);
      expect(state?.audioSourcePath, '/tmp/song.wav');
      expect(state?.beatMap, beatMap);
    },
  );

  test('completion resets play state so playback can start again', () async {
    final repository = ManualAudioPlayerRepository();
    final container = ProviderContainer(
      overrides: [audioPlayerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(playbackViewModelProvider.future);
    await container
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap: const BeatMap(
            beats: [Beat(time: Duration(milliseconds: 200), strength: 1.6)],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          audioSourcePath: '/tmp/song.wav',
        );
    await container.read(playbackViewModelProvider.notifier).play();

    repository.complete();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(playbackViewModelProvider).value;
    expect(state?.currentTime, Duration.zero);
    expect(state?.isPlaying, isFalse);
    expect(state?.isCompleted, isTrue);

    await container.read(playbackViewModelProvider.notifier).play();
    final replayState = container.read(playbackViewModelProvider).value;
    expect(repository.loadCount, 2);
    expect(repository.currentPosition, Duration.zero);
    expect(replayState?.isPlaying, isTrue);
    expect(replayState?.isCompleted, isFalse);
  });

  test('step after completion seeks forward from reset position', () async {
    final repository = ManualAudioPlayerRepository();
    final container = ProviderContainer(
      overrides: [audioPlayerRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(playbackViewModelProvider.future);
    await container
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap: const BeatMap(
            beats: [Beat(time: Duration(milliseconds: 200), strength: 1.6)],
            bpm: 120,
            averageBeatInterval: Duration(milliseconds: 500),
          ),
          audioSourcePath: '/tmp/song.wav',
        );
    repository.complete();
    await Future<void>.delayed(Duration.zero);

    await container
        .read(playbackViewModelProvider.notifier)
        .step(const Duration(seconds: 10));

    final state = container.read(playbackViewModelProvider).value;
    expect(repository.loadCount, 2);
    expect(repository.currentPosition, const Duration(seconds: 10));
    expect(state?.currentTime, const Duration(seconds: 10));
    expect(state?.isCompleted, isFalse);
  });

  test(
    'restart after completion keeps playback data and clears completed state',
    () async {
      final repository = ManualAudioPlayerRepository();
      final container = ProviderContainer(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      const beatMap = BeatMap(
        beats: [Beat(time: Duration(milliseconds: 200), strength: 1.6)],
        bpm: 120,
        averageBeatInterval: Duration(milliseconds: 500),
      );

      await container.read(playbackViewModelProvider.future);
      await container
          .read(playbackViewModelProvider.notifier)
          .preparePlayback(beatMap: beatMap, audioSourcePath: '/tmp/song.wav');
      repository.complete();
      await Future<void>.delayed(Duration.zero);

      await container.read(playbackViewModelProvider.notifier).restart();

      final state = container.read(playbackViewModelProvider).value;
      expect(repository.loadCount, 2);
      expect(repository.currentPosition, Duration.zero);
      expect(state?.beatMap, beatMap);
      expect(state?.audioSourcePath, '/tmp/song.wav');
      expect(state?.currentTime, Duration.zero);
      expect(state?.isPlaying, isFalse);
      expect(state?.isCompleted, isFalse);
    },
  );
}

class _FakeSynchronizePlaybackUseCase extends SynchronizePlaybackUseCase {
  _FakeSynchronizePlaybackUseCase({required this.results})
    : super(playbackCoordinator: const PlaybackCoordinator());

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
