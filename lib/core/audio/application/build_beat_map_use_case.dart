import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/beat_map_builder.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';

final buildBeatMapUseCaseProvider = Provider<BuildBeatMapUseCase>(
  (ref) => BuildBeatMapUseCase(
    beatMapBuilder: ref.watch(beatMapBuilderProvider),
  ),
);

class BuildBeatMapUseCase {
  const BuildBeatMapUseCase({
    required BeatMapBuilder beatMapBuilder,
  }) : _beatMapBuilder = beatMapBuilder;

  final BeatMapBuilder _beatMapBuilder;

  BeatMap call({
    required List<Beat> beats,
  }) {
    return _beatMapBuilder.build(beats: beats);
  }
}
