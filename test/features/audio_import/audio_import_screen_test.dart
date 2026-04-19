import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_result.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';

void main() {
  testWidgets('app starts on the import audio screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Import audio'), findsAtLeastNWidgets(1));
    expect(find.text('Choose audio file'), findsOneWidget);
    expect(find.text('Current process'), findsOneWidget);
  });

  testWidgets('import flow surfaces waveform and file metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importAudioUseCaseProvider.overrideWithValue(
            _FakeImportAudioUseCase(
              result: AudioImportResult(
                source: const AudioSource(
                  fileName: 'obsidian_pulse.wav',
                  fileExtension: 'wav',
                  byteLength: 256,
                  path: '/tmp/obsidian_pulse.wav',
                ),
                audioData: const AudioData(
                  samples: [0.0, 0.2, -0.4, 0.6, -0.3, 0.1],
                  sampleRate: 48000,
                  duration: Duration(minutes: 2, seconds: 15),
                  channelCount: 2,
                ),
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose audio file'));
    await tester.pumpAndSettle();

    expect(find.text('Audio ready for analysis'), findsOneWidget);
    expect(find.text('obsidian_pulse.wav'), findsWidgets);
    expect(find.text('48000 Hz'), findsOneWidget);
    expect(find.text('02:15.000'), findsOneWidget);
  });
}

class _FakeImportAudioUseCase extends ImportAudioUseCase {
  _FakeImportAudioUseCase({required this.result})
    : super(audioRepository: _NoopAudioRepository());

  final AudioImportResult? result;

  @override
  Future<AudioImportResult?> call() async {
    return result;
  }
}

class _NoopAudioRepository implements AudioRepository {
  @override
  Future<AudioImportResult?> importAudio() async {
    return null;
  }
}
