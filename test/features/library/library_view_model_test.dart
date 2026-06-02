import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';

void main() {
  test('pickImages imports images and searchChanged filters them', () async {
    final container = ProviderContainer(
      overrides: [
        imageImportRepositoryProvider.overrideWithValue(
          _FakeImageImportRepository(
            assets: [
              ImportedImageAsset(
                id: '/tmp/neon.png',
                fileName: 'Neon_City_D04.png',
                sourcePath: '/tmp/neon.png',
                bytes: Uint8List.fromList([1, 2, 3]),
                importedOn: DateTime(2026),
              ),
              ImportedImageAsset(
                id: '/tmp/range.jpg',
                fileName: 'Obsidian_Range_A01.jpg',
                sourcePath: '/tmp/range.jpg',
                bytes: Uint8List.fromList([4, 5, 6]),
                importedOn: DateTime(2026),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryViewModelProvider.notifier).pickImages();
    container.read(libraryViewModelProvider.notifier).searchChanged('neon');

    final state = container.read(libraryViewModelProvider);
    final visibleItems = state.visibleItems(const {});

    expect(state.totalCount, 2);
    expect(visibleItems, hasLength(1));
    expect(visibleItems.first.title, 'Neon_City_D04.png');
    expect(state.statusMessage, 'Added 2 images to the library.');
  });

  test('importImagesFromFolderPath stores imported items', () async {
    final container = ProviderContainer(
      overrides: [
        imageImportRepositoryProvider.overrideWithValue(
          _FakeImageImportRepository(
            assets: [
              ImportedImageAsset(
                id: '/tmp/photo.webp',
                fileName: 'Photo.webp',
                sourcePath: '/tmp/photo.webp',
                bytes: Uint8List.fromList([1]),
                importedOn: DateTime(2026),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(libraryViewModelProvider.notifier).folderPathChanged('/tmp');
    await container
        .read(libraryViewModelProvider.notifier)
        .importImagesFromFolderPath();

    final state = container.read(libraryViewModelProvider);

    expect(state.folderPathInput, '/tmp');
    expect(state.items.single.title, 'Photo.webp');
    expect(state.isImporting, isFalse);
  });

  test('reorderMedia updates staged editor order', () async {
    final container = ProviderContainer(
      overrides: [
        imageImportRepositoryProvider.overrideWithValue(
          _FakeImageImportRepository(
            assets: [
              ImportedImageAsset(
                id: '/tmp/first.png',
                fileName: 'First.png',
                sourcePath: '/tmp/first.png',
                bytes: Uint8List.fromList([1]),
                importedOn: DateTime(2026),
              ),
              ImportedImageAsset(
                id: '/tmp/second.png',
                fileName: 'Second.png',
                sourcePath: '/tmp/second.png',
                bytes: Uint8List.fromList([2]),
                importedOn: DateTime(2026),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryViewModelProvider.notifier).pickImages();
    final items = container.read(libraryViewModelProvider).items;
    container
        .read(editorMediaSelectionViewModelProvider.notifier)
        .addAllMedia(items);

    container
        .read(editorMediaSelectionViewModelProvider.notifier)
        .reorderMedia(oldIndex: 0, newIndex: 1);

    final selectedMedia = container
        .read(editorMediaSelectionViewModelProvider)
        .selectedMedia;

    expect(selectedMedia.map((item) => item.title), [
      'Second.png',
      'First.png',
    ]);
  });
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
