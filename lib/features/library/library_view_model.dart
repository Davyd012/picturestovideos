import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_state.dart';

final libraryViewModelProvider =
    NotifierProvider.autoDispose<LibraryViewModel, LibraryState>(
      LibraryViewModel.new,
    );

class LibraryViewModel extends Notifier<LibraryState> {
  static const _tag = 'LibraryViewModel';

  @override
  LibraryState build() {
    ref.read(appLoggerProvider).info(_tag, 'Initializing library state');
    return const LibraryState.initial();
  }

  void searchChanged(String query) {
    ref.read(appLoggerProvider).debug(_tag, 'Search query changed to "$query"');
    state = state.copyWith(query: query);
  }

  void folderPathChanged(String value) {
    state = state.copyWith(folderPathInput: value);
  }

  Future<void> pickImages() async {
    await _importImages(
      action: 'system picker',
      importCall: () => ref.read(imageImportRepositoryProvider).pickImages(),
    );
  }

  Future<void> importImagesFromFolderPath() async {
    final folderPath = state.folderPathInput.trim();
    await _importImages(
      action: 'folder path',
      importCall: () => ref
          .read(imageImportRepositoryProvider)
          .importImagesFromFolderPath(folderPath),
    );
  }

  void dismissMessages() {
    state = state.copyWith(clearError: true, clearStatusMessage: true);
  }

  Future<void> _importImages({
    required String action,
    required Future<List<ImportedImageAsset>> Function() importCall,
  }) async {
    ref.read(appLoggerProvider).info(_tag, 'Starting image import from $action');
    state = state.copyWith(
      isImporting: true,
      clearError: true,
      clearStatusMessage: true,
    );

    try {
      final importedAssets = await importCall();
      final mergedItems = _mergeItems(importedAssets);
      final addedCount = mergedItems.length - state.items.length;

      state = state.copyWith(
        items: List.unmodifiable(mergedItems),
        isImporting: false,
        statusMessage: addedCount == 0
            ? 'No new supported images were added.'
            : 'Added $addedCount image${addedCount == 1 ? '' : 's'} to the library.',
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref.read(appLoggerProvider).error(
        _tag,
        error,
        stackTrace,
        message: 'Image import failed from $action',
      );
      state = state.copyWith(
        isImporting: false,
        errorMessage: error.toString(),
        clearStatusMessage: true,
      );
    }
  }

  List<LibraryMediaItem> _mergeItems(List<ImportedImageAsset> importedAssets) {
    final merged = <LibraryMediaItem>[...state.items];
    final existingIds = merged.map((item) => item.id).toSet();

    for (final asset in importedAssets) {
      if (existingIds.contains(asset.id)) {
        continue;
      }

      final item = LibraryMediaItem.fromImportedImageAsset(asset);
      merged.add(item);
      existingIds.add(item.id);
    }

    return merged;
  }
}
