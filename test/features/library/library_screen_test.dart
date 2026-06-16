import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/media/data/saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/library/library_screen.dart';

void main() {
  testWidgets('library screen starts with import-focused empty state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const _LibraryTestApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsAtLeastNWidgets(1));
    expect(find.text('Image library'), findsOneWidget);
    expect(find.text('Import images'), findsOneWidget);
    expect(find.text('Pick images'), findsOneWidget);
    expect(find.text('Import folder'), findsOneWidget);
    expect(find.text('Visible: 0'), findsOneWidget);
    expect(find.text('Imported: 0'), findsOneWidget);
  });

  testWidgets('library screen imports, filters, and stages images', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const _LibraryTestApp()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pick images'));
    await tester.tap(find.text('Pick images'));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Neon_City_D04.png'), findsOneWidget);
    expect(find.text('Obsidian_Range_A01.jpg'), findsOneWidget);
    expect(find.text('Stage all imported'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'neon');
    await tester.pumpAndSettle();

    expect(find.text('Neon_City_D04.png'), findsOneWidget);
    expect(find.text('Obsidian_Range_A01.jpg'), findsNothing);

    await tester.tap(find.text('Stage').first);
    await tester.pumpAndSettle();

    expect(find.text('Ready for editor'), findsOneWidget);
    expect(find.text('Review staged'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Open editor (1)'), findsOneWidget);
  });

  testWidgets('library screen stages all imported images from toolbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const _LibraryTestApp()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pick images'));
    await tester.tap(find.text('Pick images'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Stage all imported'));
    await tester.tap(find.text('Stage all imported'));
    await tester.pumpAndSettle();

    expect(find.text('Ready for editor'), findsOneWidget);
    expect(find.text('Staged: 2'), findsWidgets);
    expect(find.text('Open editor (2)'), findsOneWidget);
  });
}

class _LibraryTestApp extends StatelessWidget {
  const _LibraryTestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LibraryScreen());
  }
}

dynamic _overrides() {
  return [
    imageImportRepositoryProvider.overrideWithValue(
      _FakeImageImportRepository(
        assets: [
          ImportedImageAsset(
            id: '/tmp/neon.png',
            fileName: 'Neon_City_D04.png',
            sourcePath: '/tmp/neon.png',
            bytes: Uint8List.fromList([1, 2, 3]),
            importedOn: DateTime(2026, 1, 2),
          ),
          ImportedImageAsset(
            id: '/tmp/range.jpg',
            fileName: 'Obsidian_Range_A01.jpg',
            sourcePath: '/tmp/range.jpg',
            bytes: Uint8List.fromList([4, 5, 6]),
            importedOn: DateTime(2026, 1),
          ),
        ],
      ),
    ),
    savedImageAssetRepositoryProvider.overrideWithValue(
      _MemorySavedImageAssetRepository(),
    ),
  ];
}

class _FakeImageImportRepository implements ImageImportRepository {
  const _FakeImageImportRepository({required this.assets});

  final List<ImportedImageAsset> assets;

  @override
  Future<List<ImportedImageAsset>> pickImages() async {
    return assets;
  }

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPath(
    String folderPath,
  ) async {
    return assets;
  }
}

class _MemorySavedImageAssetRepository implements SavedImageAssetRepository {
  final List<SavedImageAsset> assets = [];

  @override
  Future<void> clear() async {
    assets.clear();
  }

  @override
  Future<List<SavedImageAsset>> loadAll() async {
    return List.unmodifiable(assets);
  }

  @override
  Future<void> upsertAll(List<SavedImageAsset> assets) async {
    for (final asset in assets) {
      this.assets.removeWhere((currentAsset) => currentAsset.id == asset.id);
      this.assets.add(asset);
    }
  }
}
