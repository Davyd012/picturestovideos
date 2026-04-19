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
  }) : this._(beatMapBuilder);

  const BuildBeatMapUseCase._(this._beatMapBuilder);

  final BeatMapBuilder _beatMapBuilder;

  BeatMap call({
    required List<Beat> beats,
  }) {
    return _beatMapBuilder.build(beats: beats);
  }
}
