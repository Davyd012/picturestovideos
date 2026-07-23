import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/media/data/saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/features/home/home_view_model.dart';

void main() {
  test('loads saved audio and assets sorted newest first', () async {
    final container = ProviderContainer(
      overrides: [
        audioMarkerPresetRepositoryProvider.overrideWithValue(
          _MemoryAudioMarkerPresetRepository(
            presets: [
              _preset('old', DateTime(2026, 1)),
              _preset('new', DateTime(2026, 2)),
            ],
          ),
        ),
        savedImageAssetRepositoryProvider.overrideWithValue(
          _MemorySavedImageAssetRepository(
            assets: [
              _asset('old.png', DateTime(2026, 1)),
              _asset('new.png', DateTime(2026, 2)),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.audioPresets.map((preset) => preset.sourceName), [
      'new.wav',
      'old.wav',
    ]);
    expect(state.imageAssets.map((asset) => asset.fileName), [
      'new.png',
      'old.png',
    ]);
  });

  test('openSavedAudio reports missing saved audio path', () async {
    final container = ProviderContainer(
      overrides: [
        audioMarkerPresetRepositoryProvider.overrideWithValue(
          _MemoryAudioMarkerPresetRepository(),
        ),
        savedImageAssetRepositoryProvider.overrideWithValue(
          _MemorySavedImageAssetRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(homeViewModelProvider.future);
    final opened = await container
        .read(homeViewModelProvider.notifier)
        .openSavedAudio(_preset('missing', DateTime(2026), sourcePath: null));

    expect(opened, isFalse);
    expect(
      container.read(homeViewModelProvider).value?.statusMessage,
      'This saved audio does not have a file path.',
    );
  });
}

AudioMarkerPreset _preset(
  String name,
  DateTime updatedAt, {
  String? sourcePath = '/tmp/audio.wav',
}) {
  return AudioMarkerPreset(
    version: 1,
    audioSignature: 'signature-$name',
    sourceName: '$name.wav',
    sourcePath: sourcePath,
    sourceExtension: 'wav',
    byteLength: 128,
    duration: const Duration(seconds: 2),
    updatedAt: updatedAt,
    markers: const [
      BeatEvent(time: Duration(milliseconds: 300), type: 'marker'),
    ],
  );
}

SavedImageAsset _asset(String fileName, DateTime importedOn) {
  return SavedImageAsset(
    id: '/tmp/$fileName',
    fileName: fileName,
    sourcePath: '/tmp/$fileName',
    byteLength: 1024,
    importedOn: importedOn,
  );
}

class _MemoryAudioMarkerPresetRepository
    implements AudioMarkerPresetRepository {
  _MemoryAudioMarkerPresetRepository({
    List<AudioMarkerPreset> presets = const [],
  }) : _presets = [...presets];

  final List<AudioMarkerPreset> _presets;

  @override
  Future<void> clear() async {
    _presets.clear();
  }

  @override
  Future<AudioMarkerPreset?> load({required String audioSignature}) async {
    for (final preset in _presets) {
      if (preset.audioSignature == audioSignature) {
        return preset;
      }
    }
    return null;
  }

  @override
  Future<List<AudioMarkerPreset>> loadAll() async {
    return List.unmodifiable(_presets);
  }

  @override
  Future<void> save(AudioMarkerPreset preset) async {
    _presets.removeWhere(
      (currentPreset) => currentPreset.audioSignature == preset.audioSignature,
    );
    _presets.add(preset);
  }
}

class _MemorySavedImageAssetRepository implements SavedImageAssetRepository {
  _MemorySavedImageAssetRepository({List<SavedImageAsset> assets = const []})
    : _assets = [...assets];

  final List<SavedImageAsset> _assets;

  @override
  Future<void> clear() async {
    _assets.clear();
  }

  @override
  Future<List<SavedImageAsset>> loadAll() async {
    return List.unmodifiable(_assets);
  }

  @override
  Future<void> removeAll(Set<String> ids) async {
    _assets.removeWhere((asset) => ids.contains(asset.id));
  }

  @override
  Future<void> upsertAll(List<SavedImageAsset> assets) async {
    for (final asset in assets) {
      _assets.removeWhere((currentAsset) => currentAsset.id == asset.id);
      _assets.add(asset);
    }
  }
}
