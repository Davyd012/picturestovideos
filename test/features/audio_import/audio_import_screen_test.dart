import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app.dart';
import 'package:picturestovideos/core/audio/application/analyze_audio_frames_use_case.dart';
import 'package:picturestovideos/core/audio/application/beat_detector.dart';
import 'package:picturestovideos/core/audio/application/decode_wav_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/detect_beats_use_case.dart';
import 'package:picturestovideos/core/audio/application/frame_energy_analyzer.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/prepare_audio_for_analysis_use_case.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/data/audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/audio_processing_task.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';

void main() {
  testWidgets('app starts on the empty import audio screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Import audio'), findsAtLeastNWidgets(1));
    expect(find.text('Drop a WAV file here'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
    expect(find.text('Current process'), findsNothing);
    expect(find.text('Recent tracks'), findsNothing);
  });

  testWidgets('import flow renders completed state and pipeline sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(overrides: _audioImportOverrides(), child: const App()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();

    expect(find.text('Import complete'), findsOneWidget);
    expect(find.text('beat.wav'), findsWidgets);
    expect(find.text('44100 Hz'), findsOneWidget);
    expect(find.text('Go to editor'), findsOneWidget);

    await tester.ensureVisible(find.text('View pipeline progress'));
    await tester.tap(find.text('View pipeline progress'));
    await tester.pumpAndSettle();

    expect(find.text('Pipeline progress'), findsOneWidget);
    expect(find.text('Beat detection'), findsOneWidget);
  });
}

dynamic _audioImportOverrides() {
  final audioData = const AudioData(
    samples: [0.0, 0.8, -0.4, 0.6, -0.2, 0.3],
    sampleRate: 44100,
    duration: Duration(seconds: 2),
    channelCount: 1,
  );
  final frames = const [
    AudioFrame(time: Duration.zero, energy: 0.2),
    AudioFrame(time: Duration(milliseconds: 500), energy: 0.9),
    AudioFrame(time: Duration(seconds: 1), energy: 0.2),
  ];
  final beats = const [
    Beat(time: Duration.zero, strength: 1),
    Beat(time: Duration(milliseconds: 500), strength: 1),
    Beat(time: Duration(seconds: 1), strength: 1),
  ];

  return [
    importAudioUseCaseProvider.overrideWithValue(
      _FakeImportAudioUseCase(result: _selectedAudioFile()),
    ),
    prepareAudioForAnalysisUseCaseProvider.overrideWithValue(
      _FakePrepareAudioForAnalysisUseCase(),
    ),
    decodeWavAudioUseCaseProvider.overrideWithValue(
      _FakeDecodeWavAudioUseCase(audioData: audioData),
    ),
    analyzeAudioFramesUseCaseProvider.overrideWithValue(
      _FakeAnalyzeAudioFramesUseCase(frames: frames),
    ),
    detectBeatsUseCaseProvider.overrideWithValue(
      _FakeDetectBeatsUseCase(beats: beats),
    ),
    audioPlayerRepositoryProvider.overrideWithValue(
      ManualAudioPlayerRepository(),
    ),
  ];
}

SelectedAudioFile _selectedAudioFile() {
  return SelectedAudioFile(
    source: const AudioSource(
      fileName: 'beat.wav',
      fileExtension: 'wav',
      byteLength: 128,
      path: '/tmp/beat.wav',
    ),
    bytes: Uint8List.fromList(const [
      82,
      73,
      70,
      70,
      0,
      0,
      0,
      0,
      87,
      65,
      86,
      69,
    ]),
  );
}

class _FakeImportAudioUseCase extends ImportAudioUseCase {
  _FakeImportAudioUseCase({required this.result})
    : super(audioRepository: _NoopAudioRepository());

  final SelectedAudioFile? result;

  @override
  Future<SelectedAudioFile?> call() async {
    return result;
  }
}

class _FakePrepareAudioForAnalysisUseCase
    extends PrepareAudioForAnalysisUseCase {
  _FakePrepareAudioForAnalysisUseCase() : super(logger: AppLogger(appTalker));

  @override
  Future<SelectedAudioFile> call(SelectedAudioFile selectedFile) async {
    return selectedFile;
  }
}

class _FakeDecodeWavAudioUseCase extends DecodeWavAudioUseCase {
  const _FakeDecodeWavAudioUseCase({required this.audioData});

  final AudioData audioData;

  @override
  Future<AudioData> call({required DecodeWavAudioRequest request}) async {
    return audioData;
  }
}

class _FakeAnalyzeAudioFramesUseCase extends AnalyzeAudioFramesUseCase {
  _FakeAnalyzeAudioFramesUseCase({required this.frames})
    : super(frameEnergyAnalyzer: const _NoopFrameEnergyAnalyzer());

  final List<AudioFrame> frames;

  @override
  Future<List<AudioFrame>> call({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) async {
    return frames;
  }
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

class _NoopFrameEnergyAnalyzer extends FrameEnergyAnalyzer {
  const _NoopFrameEnergyAnalyzer();

  @override
  List<AudioFrame> analyze({
    required AudioData audioData,
    AudioAnalysisConfig config = const AudioAnalysisConfig.defaults(),
  }) {
    return const [];
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

class _NoopAudioRepository implements AudioRepository {
  @override
  Future<SelectedAudioFile?> importAudio() async {
    return null;
  }

  @override
  Future<SelectedAudioFile> importAudioFromPath(String path) async {
    return _selectedAudioFile();
  }
}
