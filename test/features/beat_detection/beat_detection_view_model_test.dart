import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/application/detect_beats_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_state.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';

void main() {
  test('detectBeats stores generated beat list', () async {
    final container = ProviderContainer(
      overrides: [
        detectBeatsUseCaseProvider.overrideWithValue(
          _FakeDetectBeatsUseCase(
            beats: const [
              Beat(time: Duration(milliseconds: 200), strength: 1.6),
              Beat(time: Duration(milliseconds: 500), strength: 1.8),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(beatDetectionViewModelProvider.future);
    await container.read(beatDetectionViewModelProvider.notifier).detectBeats(
      const [AudioFrame(time: Duration.zero, energy: 0.1)],
    );

    final state = container.read(beatDetectionViewModelProvider);

    expect(state, isA<AsyncData<BeatDetectionState>>());
    expect(state.value?.beatCount, 2);
    expect(state.value?.firstBeat?.time, const Duration(milliseconds: 200));
  });
}

class _FakeDetectBeatsUseCase extends DetectBeatsUseCase {
  _FakeDetectBeatsUseCase({required this.beats})
    : super(beatDetector: const _NoopBeatDetector());

  final List<Beat> beats;

  @override
  Future<List<Beat>> call({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) async {
    return beats;
  }
}

class _NoopBeatDetector extends BeatDetector {
  const _NoopBeatDetector();

  @override
  List<Beat> detect({
    required List<AudioFrame> frames,
    BeatDetectionConfig config = const BeatDetectionConfig.defaults(),
  }) {
    return const [];
  }
}
