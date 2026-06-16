import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('saves multiple marker presets and loads by signature', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = SharedPreferencesAudioMarkerPresetRepository();

    await repository.save(
      AudioMarkerPreset(
        version: 1,
        audioSignature: 'signature-old',
        sourceName: 'old.wav',
        sourcePath: '/tmp/old.wav',
        sourceExtension: 'wav',
        byteLength: 2048,
        duration: const Duration(seconds: 1),
        updatedAt: DateTime(2026, 1),
        markers: const [
          BeatEvent(time: Duration(milliseconds: 200), type: 'marker'),
        ],
      ),
    );
    await repository.save(
      AudioMarkerPreset(
        version: 1,
        audioSignature: 'signature-new',
        sourceName: 'new.wav',
        sourcePath: '/tmp/new.wav',
        sourceExtension: 'wav',
        byteLength: 4096,
        duration: const Duration(seconds: 2),
        updatedAt: DateTime(2026, 2),
        markers: const [
          BeatEvent(time: Duration(milliseconds: 300), type: 'marker'),
          BeatEvent(time: Duration(milliseconds: 900), type: 'marker'),
        ],
      ),
    );

    final presets = await repository.loadAll();
    final loaded = await repository.load(audioSignature: 'signature-new');

    expect(presets.map((preset) => preset.audioSignature), [
      'signature-new',
      'signature-old',
    ]);
    expect(loaded?.sourcePath, '/tmp/new.wav');
    expect(loaded?.sourceExtension, 'wav');
    expect(loaded?.byteLength, 4096);
    expect(loaded?.duration, const Duration(seconds: 2));
    expect(loaded?.markers, hasLength(2));
  });

  test('save replaces preset with the same audio signature', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = SharedPreferencesAudioMarkerPresetRepository();

    await repository.save(
      AudioMarkerPreset(
        version: 1,
        audioSignature: 'signature',
        sourceName: 'first.wav',
        updatedAt: DateTime(2026, 1),
        markers: const [
          BeatEvent(time: Duration(milliseconds: 200), type: 'marker'),
        ],
      ),
    );
    await repository.save(
      AudioMarkerPreset(
        version: 1,
        audioSignature: 'signature',
        sourceName: 'second.wav',
        updatedAt: DateTime(2026, 2),
        markers: const [
          BeatEvent(time: Duration(milliseconds: 400), type: 'marker'),
          BeatEvent(time: Duration(milliseconds: 800), type: 'marker'),
        ],
      ),
    );

    final presets = await repository.loadAll();

    expect(presets, hasLength(1));
    expect(presets.single.sourceName, 'second.wav');
    expect(presets.single.markers, hasLength(2));
  });
}
