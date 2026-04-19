import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_result.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';

void main() {
  test('pickAudioFile stores imported audio metadata', () async {
    final container = ProviderContainer(
      overrides: [
        importAudioUseCaseProvider.overrideWithValue(
          _FakeImportAudioUseCase(
            result: AudioImportResult(
              source: const AudioSource(
                fileName: 'beat.wav',
                fileExtension: 'wav',
                byteLength: 128,
                path: '/tmp/beat.wav',
              ),
              audioData: const AudioData(
                samples: [0.0, 0.25, -0.25],
                sampleRate: 44100,
                duration: Duration(milliseconds: 68),
                channelCount: 1,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(audioImportViewModelProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(audioImportViewModelProvider.future);
    await container.read(audioImportViewModelProvider.notifier).pickAudioFile();

    final state = container.read(audioImportViewModelProvider);

    expect(state, isA<AsyncData<AudioImportState>>());
    expect(state.value?.source?.fileName, 'beat.wav');
    expect(state.value?.audioData?.sampleRate, 44100);
    expect(state.value?.audioData?.samples.length, 3);
  });
}

class _FakeImportAudioUseCase extends ImportAudioUseCase {
  _FakeImportAudioUseCase({
    required this._result,
  }) : super(audioRepository: _NoopAudioRepository());

  final AudioImportResult? _result;

  @override
  Future<AudioImportResult?> call() async {
    return _result;
  }
}

class _NoopAudioRepository implements AudioRepository {
  @override
  Future<AudioImportResult?> importAudio() async {
    return null;
  }
}
