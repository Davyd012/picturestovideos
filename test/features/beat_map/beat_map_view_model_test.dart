import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/beat_map_builder.dart';
import 'package:picturestovideos/core/audio/application/build_beat_map_use_case.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';

void main() {
  test('buildBeatMap stores generated beat map', () async {
    final container = ProviderContainer(
      overrides: [
        buildBeatMapUseCaseProvider.overrideWithValue(
          _FakeBuildBeatMapUseCase(
            beatMap: const BeatMap(
              beats: [
                Beat(
                  time: Duration(milliseconds: 200),
                  strength: 1.6,
                ),
                Beat(
                  time: Duration(milliseconds: 700),
                  strength: 1.5,
                ),
              ],
              bpm: 120,
              averageBeatInterval: Duration(milliseconds: 500),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(beatMapViewModelProvider.future);
    await container.read(beatMapViewModelProvider.notifier).buildBeatMap(
          const [
            Beat(
              time: Duration(milliseconds: 200),
              strength: 1.6,
            ),
          ],
        );

    final state = container.read(beatMapViewModelProvider);

    expect(state, isA<AsyncData<BeatMapState>>());
    expect(state.value?.beatMap.bpm, 120);
    expect(
      state.value?.beatMap.averageBeatInterval,
      const Duration(milliseconds: 500),
    );
  });
}

class _FakeBuildBeatMapUseCase extends BuildBeatMapUseCase {
  _FakeBuildBeatMapUseCase({
    required this.beatMap,
  }) : super(beatMapBuilder: const BeatMapBuilder());

  final BeatMap beatMap;

  @override
  BeatMap call({
    required List<Beat> beats,
  }) {
    return beatMap;
  }
}
