import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
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

  testWidgets('library empty state uses the selected locale', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: const _LibraryTestApp(locale: Locale('ru')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Библиотека изображений'), findsOneWidget);
    expect(find.text('Импорт фотографий'), findsOneWidget);
    expect(find.text('Выбрать фотографии'), findsOneWidget);
    expect(find.text('Импортировать папку'), findsOneWidget);
  });

  testWidgets('Android offers the SAF folder picker', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: const _LibraryTestApp(locale: Locale('ru')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Выберите папку через системный выбор Android. Импортируются только поддерживаемые изображения из этой папки.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Импортировать папку'),
            )
            .onPressed,
        isNotNull,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('library errors are localized and hide exception details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(error: StateError('native internal detail')),
        child: const _LibraryTestApp(locale: Locale('ru')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Импортировать папку'));
    await tester.tap(find.text('Импортировать папку'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Не удалось импортировать фотографии. Проверьте файлы и попробуйте ещё раз.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('native internal detail'), findsNothing);
  });

  testWidgets('populated library toolbar and import status are localized', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: const _LibraryTestApp(locale: Locale('ru')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Выбрать фотографии'));
    await tester.tap(find.text('Выбрать фотографии'));
    await tester.pumpAndSettle();

    expect(find.text('Сортировка'), findsWidgets);
    expect(find.text('Все'), findsOneWidget);
    expect(find.text('Недавние'), findsOneWidget);
    expect(find.text('Избранное'), findsOneWidget);
    expect(find.text('Добавить все импортированные'), findsOneWidget);
    expect(find.text('Добавлено 2 изображения в библиотеку.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration!
          .hintText,
      'Поиск фотографий, папок и дат',
    );
    await tester.ensureVisible(find.text('Импортировать ещё'));
    await tester.tap(find.text('Импортировать ещё'));
    await tester.pumpAndSettle();
    expect(
      find.text('Новые поддерживаемые фотографии не добавлены.'),
      findsOneWidget,
    );
  });

  testWidgets('library screen imports, filters, and stages images', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
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

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search images, folders, or dates',
    );
    expect(tester.widget<TextField>(searchField).enabled, isTrue);
    await tester.enterText(searchField, 'neon');
    await tester.pumpAndSettle();

    expect(find.text('Neon_City_D04.png'), findsOneWidget);
    expect(find.text('Obsidian_Range_A01.jpg'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Stage').first,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Stage').first);
    await tester.pumpAndSettle();

    expect(find.text('Ready for editor'), findsOneWidget);
    expect(find.text('Review staged'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Open editor (1)'), findsWidgets);
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
    expect(find.text('Open editor (2)'), findsWidgets);
  });
}

class _LibraryTestApp extends StatelessWidget {
  const _LibraryTestApp({this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LibraryScreen(),
    );
  }
}

dynamic _overrides({Object? error}) {
  return [
    imageImportRepositoryProvider.overrideWithValue(
      _FakeImageImportRepository(
        error: error,
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
  const _FakeImageImportRepository({required this.assets, this.error});

  final List<ImportedImageAsset> assets;
  final Object? error;

  @override
  Future<List<ImportedImageAsset>> pickImages() async {
    if (error != null) throw error!;
    return assets;
  }

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPath(
    String folderPath,
  ) async {
    if (error != null) throw error!;
    return assets;
  }

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPicker() async {
    if (error != null) throw error!;
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
  Future<void> removeAll(Set<String> ids) async {
    assets.removeWhere((asset) => ids.contains(asset.id));
  }

  @override
  Future<void> upsertAll(List<SavedImageAsset> assets) async {
    for (final asset in assets) {
      this.assets.removeWhere((currentAsset) => currentAsset.id == asset.id);
      this.assets.add(asset);
    }
  }
}
