import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';

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

  void filterSelected(LibraryFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void sortOrderSelected(LibrarySortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void itemSelectionToggled(String itemId) {
    final selectedIds = {...state.selectedItemIds};
    if (selectedIds.contains(itemId)) {
      selectedIds.remove(itemId);
    } else {
      selectedIds.add(itemId);
    }
    state = state.copyWith(selectedItemIds: Set.unmodifiable(selectedIds));
  }

  void itemSelectionRemoved(String itemId) {
    if (!state.selectedItemIds.contains(itemId)) {
      return;
    }

    final selectedIds = {...state.selectedItemIds}..remove(itemId);
    state = state.copyWith(selectedItemIds: Set.unmodifiable(selectedIds));
  }

  void clearItemSelection() {
    state = state.copyWith(selectedItemIds: const {});
  }

  void reviewStagedOpened() {
    state = state.copyWith(isReviewingStaged: true);
  }

  void libraryOpened() {
    state = state.copyWith(isReviewingStaged: false);
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

  Future<void> removeImportedImages(Set<String> itemIds) async {
    if (itemIds.isEmpty) {
      return;
    }
    state = state.copyWith(
      isImporting: true,
      clearError: true,
      clearStatusMessage: true,
    );
    try {
      await ref.read(savedImageAssetRepositoryProvider).removeAll(itemIds);
      ref
          .read(editorMediaSelectionViewModelProvider.notifier)
          .removeAllMedia(itemIds);
      state = state.copyWith(
        items: List.unmodifiable(
          state.items.where((item) => !itemIds.contains(item.id)),
        ),
        selectedItemIds: const {},
        isImporting: false,
        statusMessage:
            'Removed ${itemIds.length} image${itemIds.length == 1 ? '' : 's'} from the app.',
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            _tag,
            error,
            stackTrace,
            message: 'Removing imported images failed',
          );
      state = state.copyWith(
        isImporting: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _importImages({
    required String action,
    required Future<List<ImportedImageAsset>> Function() importCall,
  }) async {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Starting image import from $action');
    state = state.copyWith(
      isImporting: true,
      clearError: true,
      clearStatusMessage: true,
    );

    try {
      final importedAssets = await importCall();
      await ref
          .read(savedImageAssetRepositoryProvider)
          .upsertAll(_savedAssetsFromImportedAssets(importedAssets));
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
      ref
          .read(appLoggerProvider)
          .error(
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

  List<SavedImageAsset> _savedAssetsFromImportedAssets(
    List<ImportedImageAsset> importedAssets,
  ) {
    return [
      for (final asset in importedAssets)
        SavedImageAsset(
          id: asset.id,
          fileName: asset.fileName,
          sourcePath: asset.sourcePath,
          byteLength: asset.byteLength,
          importedOn: asset.importedOn,
          fileModifiedOn: asset.fileModifiedOn,
          importOrder: asset.importOrder,
        ),
    ];
  }
}
