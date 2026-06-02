import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/build_beat_map_use_case.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';

final beatMapViewModelProvider =
    AsyncNotifierProvider<BeatMapViewModel, BeatMapState>(BeatMapViewModel.new);

class BeatMapViewModel extends AsyncNotifier<BeatMapState> {
  static const _tag = 'BeatMapViewModel';

  @override
  Future<BeatMapState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing beat map state');
    return const BeatMapState.initial();
  }

  Future<void> buildBeatMap(List<Beat> beats) async {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Building beat map from ${beats.length} beats');
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final beatMap = ref.read(buildBeatMapUseCaseProvider).call(beats: beats);

      return BeatMapState(beatMap: beatMap);
    });
  }

  void reset() {
    state = const AsyncData(BeatMapState.initial());
  }
}
