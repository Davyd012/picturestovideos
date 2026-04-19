import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/detect_beats_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_state.dart';

final beatDetectionViewModelProvider = AsyncNotifierProvider.autoDispose<
    BeatDetectionViewModel, BeatDetectionState>(
  BeatDetectionViewModel.new,
);

class BeatDetectionViewModel extends AsyncNotifier<BeatDetectionState> {
  @override
  Future<BeatDetectionState> build() async {
    return const BeatDetectionState.initial();
  }

  Future<void> detectBeats(
    List<AudioFrame> frames, {
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final beats = ref.read(detectBeatsUseCaseProvider).call(
            frames: frames,
            config: config,
          );

      return BeatDetectionState(
        config: config,
        beats: beats,
      );
    });
  }
}
