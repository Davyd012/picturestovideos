import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/build_beat_map_use_case.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';

final beatMapViewModelProvider =
    AsyncNotifierProvider.autoDispose<BeatMapViewModel, BeatMapState>(
  BeatMapViewModel.new,
);

class BeatMapViewModel extends AsyncNotifier<BeatMapState> {
  @override
  Future<BeatMapState> build() async {
    return const BeatMapState.initial();
  }

  Future<void> buildBeatMap(List<Beat> beats) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final beatMap = ref.read(buildBeatMapUseCaseProvider).call(beats: beats);

      return BeatMapState(beatMap: beatMap);
    });
  }
}
