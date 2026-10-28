import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/media/data/saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/home/home_screen.dart';

void main() {
  testWidgets('home screen renders saved audio and saved assets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          presets: [_preset(sourcePath: '/tmp/beat.wav')],
          assets: [_asset()],
        ),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Saved media'), findsOneWidget);
    expect(find.text('Saved audio'), findsOneWidget);
    expect(find.text('beat.wav'), findsOneWidget);
    expect(find.text('Saved assets'), findsOneWidget);
    expect(find.text('frame.png'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('home screen shows missing path state for saved audio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(presets: [_preset(sourcePath: null)]),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('This saved audio does not have a file path.'),
      findsOneWidget,
    );
  });

  testWidgets('Russian home screen and navigation use one locale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsAtLeastNWidgets(1));
    expect(find.text('Сохранённые проекты'), findsOneWidget);
    expect(find.text('Сохранённые материалы'), findsOneWidget);
    expect(find.text('Сохранённое аудио'), findsOneWidget);
    expect(find.text('Сохранённые изображения'), findsOneWidget);
    expect(find.text('Библиотека'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Saved media'), findsNothing);
    expect(find.text('Saved audio'), findsNothing);
  });
}

dynamic _overrides({
  List<AudioMarkerPreset> presets = const [],
  List<SavedImageAsset> assets = const [],
}) {
  return [
    projectRepositoryProvider.overrideWithValue(_MemoryProjectRepository()),
    audioMarkerPresetRepositoryProvider.overrideWithValue(
      _MemoryAudioMarkerPresetRepository(presets: presets),
    ),
    savedImageAssetRepositoryProvider.overrideWithValue(
      _MemorySavedImageAssetRepository(assets: assets),
    ),
  ];
}

class _MemoryProjectRepository implements ProjectRepository {
  @override
  List<ProjectStorageIssue> get lastLoadIssues => const [];

  @override
  Future<List<ProjectTimeline>> loadAll() async => const [];
  @override
  Future<void> save(ProjectTimeline project) async {}
}

AudioMarkerPreset _preset({String? sourcePath}) {
  return AudioMarkerPreset(
    version: 1,
    audioSignature: 'signature',
    sourceName: 'beat.wav',
    sourcePath: sourcePath,
    sourceExtension: 'wav',
    byteLength: 128,
    duration: const Duration(seconds: 2),
    updatedAt: DateTime(2026, 6, 9),
    markers: const [
      BeatEvent(time: Duration(milliseconds: 300), type: 'marker'),
    ],
  );
}

SavedImageAsset _asset() {
  return SavedImageAsset(
    id: '/tmp/frame.png',
    fileName: 'frame.png',
    sourcePath: '/tmp/frame.png',
    byteLength: 1024,
    importedOn: DateTime(2026, 6, 9),
  );
}

class _MemoryAudioMarkerPresetRepository
    implements AudioMarkerPresetRepository {
  const _MemoryAudioMarkerPresetRepository({required this.presets});

  final List<AudioMarkerPreset> presets;

  @override
  Future<void> clear() async {}

  @override
  Future<AudioMarkerPreset?> load({required String audioSignature}) async {
    for (final preset in presets) {
      if (preset.audioSignature == audioSignature) {
        return preset;
      }
    }
    return null;
  }

  @override
  Future<List<AudioMarkerPreset>> loadAll() async {
    return presets;
  }

  @override
  Future<void> save(AudioMarkerPreset preset) async {}
}

class _MemorySavedImageAssetRepository implements SavedImageAssetRepository {
  const _MemorySavedImageAssetRepository({required this.assets});

  final List<SavedImageAsset> assets;

  @override
  Future<void> clear() async {}

  @override
  Future<List<SavedImageAsset>> loadAll() async {
    return assets;
  }

  @override
  Future<void> removeAll(Set<String> ids) async {}

  @override
  Future<void> upsertAll(List<SavedImageAsset> assets) async {}
}
