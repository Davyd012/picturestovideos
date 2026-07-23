import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

final editorMediaSelectionViewModelProvider =
    NotifierProvider<EditorMediaSelectionViewModel, EditorMediaSelectionState>(
      EditorMediaSelectionViewModel.new,
    );

class EditorMediaSelectionViewModel
    extends Notifier<EditorMediaSelectionState> {
  static const _tag = 'EditorMediaSelectionViewModel';

  @override
  EditorMediaSelectionState build() {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Initializing editor media selection state');
    return const EditorMediaSelectionState.initial();
  }

  void toggleMedia(LibraryMediaItem item) {
    if (state.containsMedia(item.id)) {
      removeMedia(item.id);
      return;
    }

    addMedia(item);
  }

  void addMedia(LibraryMediaItem item) {
    if (state.containsMedia(item.id)) {
      return;
    }

    ref
        .read(appLoggerProvider)
        .info(_tag, 'Adding media ${item.id} to editor selection');
    state = state.copyWith(
      selectedMedia: List.unmodifiable([...state.selectedMedia, item]),
    );
    _syncTimelineMedia();
  }

  void addAllMedia(List<LibraryMediaItem> items) {
    if (items.isEmpty) {
      return;
    }

    final merged = [...state.selectedMedia];
    for (final item in items) {
      final exists = merged.any((selected) => selected.id == item.id);
      if (!exists) {
        merged.add(item);
      }
    }

    ref
        .read(appLoggerProvider)
        .info(
          _tag,
          'Added ${merged.length - state.selectedMedia.length} media items to editor selection',
        );
    state = state.copyWith(selectedMedia: List.unmodifiable(merged));
    _syncTimelineMedia();
  }

  void removeMedia(String mediaId) {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Removing media $mediaId from editor selection');
    final updatedFits = Map<String, VideoTemplateImageFit>.from(
      state.selectedImageFits,
    )..remove(mediaId);
    final updatedTransforms = Map<String, ImageCropTransform>.from(
      state.selectedCropTransforms,
    )..remove(mediaId);
    state = state.copyWith(
      selectedMedia: List.unmodifiable(
        state.selectedMedia.where((item) => item.id != mediaId),
      ),
      selectedImageFits: Map.unmodifiable(updatedFits),
      selectedCropTransforms: Map.unmodifiable(updatedTransforms),
    );
    _syncTimelineMedia();
  }

  void reorderMedia({required int oldIndex, required int newIndex}) {
    final selectedMedia = [...state.selectedMedia];
    if (oldIndex < 0 || oldIndex >= selectedMedia.length) {
      return;
    }

    if (newIndex < 0 || newIndex >= selectedMedia.length) {
      return;
    }

    final item = selectedMedia.removeAt(oldIndex);
    selectedMedia.insert(newIndex, item);
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Reordered media ${item.id} from $oldIndex to $newIndex');
    state = state.copyWith(
      selectedMedia: List.unmodifiable(selectedMedia),
      sequenceSort: StagedSequenceSort.custom,
    );
    _syncTimelineMedia();
  }

  void moveMediaToPosition({required String mediaId, required int position}) {
    final items = [...state.selectedMedia];
    final oldIndex = items.indexWhere((item) => item.id == mediaId);
    if (oldIndex < 0 || position < 1 || position > items.length) {
      return;
    }
    final item = items.removeAt(oldIndex);
    items.insert(position - 1, item);
    state = state.copyWith(
      selectedMedia: List.unmodifiable(items),
      sequenceSort: StagedSequenceSort.custom,
    );
    _syncTimelineMedia();
  }

  void sortSequence(StagedSequenceSort sort) {
    if (sort == StagedSequenceSort.custom) {
      return;
    }
    final ascending = state.sequenceSort == sort ? state.isSortAscending : true;
    final indexed = state.selectedMedia.indexed.toList();
    indexed.sort((first, second) {
      final result = switch (sort) {
        StagedSequenceSort.importOrder => first.$2.importOrder.compareTo(
          second.$2.importOrder,
        ),
        StagedSequenceSort.title => first.$2.title.toLowerCase().compareTo(
          second.$2.title.toLowerCase(),
        ),
        StagedSequenceSort.fileDate =>
          (first.$2.fileModifiedOn ?? first.$2.importedOn).compareTo(
            second.$2.fileModifiedOn ?? second.$2.importedOn,
          ),
        StagedSequenceSort.custom => 0,
      };
      final stableResult = result == 0 ? first.$1.compareTo(second.$1) : result;
      return ascending ? stableResult : -stableResult;
    });
    state = state.copyWith(
      selectedMedia: List.unmodifiable([for (final entry in indexed) entry.$2]),
      sequenceSort: sort,
      isSortAscending: ascending,
    );
    _syncTimelineMedia();
  }

  void reverseSequence() {
    state = state.copyWith(
      selectedMedia: List.unmodifiable(state.selectedMedia.reversed),
      isSortAscending: !state.isSortAscending,
    );
    _syncTimelineMedia();
  }

  void imageFitSelected({
    required String mediaId,
    required VideoTemplateImageFit imageFit,
  }) {
    if (!state.containsMedia(mediaId)) {
      return;
    }

    ref
        .read(appLoggerProvider)
        .info(_tag, 'Changed image fit for $mediaId to ${imageFit.name}');
    state = state.copyWith(
      selectedImageFits: Map.unmodifiable({
        ...state.selectedImageFits,
        mediaId: imageFit,
      }),
    );
    ref
        .read(timelineViewModelProvider.notifier)
        .updateMediaImageFit(mediaId: mediaId, imageFit: imageFit);
  }

  void imageFitSelectedForAll(VideoTemplateImageFit imageFit) {
    final fits = {for (final item in state.selectedMedia) item.id: imageFit};
    state = state.copyWith(selectedImageFits: Map.unmodifiable(fits));
    ref
        .read(timelineViewModelProvider.notifier)
        .updateAllMediaImageFits(imageFit);
  }

  void cropTransformChanged({
    required String mediaId,
    required ImageCropTransform transform,
  }) {
    if (!state.containsMedia(mediaId)) {
      return;
    }
    state = state.copyWith(
      selectedCropTransforms: Map.unmodifiable({
        ...state.selectedCropTransforms,
        mediaId: transform,
      }),
    );
    ref
        .read(timelineViewModelProvider.notifier)
        .updateMediaCropTransform(mediaId: mediaId, transform: transform);
  }

  void removeAllMedia(Set<String> mediaIds) {
    if (mediaIds.isEmpty) {
      return;
    }
    final fits = Map<String, VideoTemplateImageFit>.from(
      state.selectedImageFits,
    )..removeWhere((id, _) => mediaIds.contains(id));
    final transforms = Map<String, ImageCropTransform>.from(
      state.selectedCropTransforms,
    )..removeWhere((id, _) => mediaIds.contains(id));
    state = state.copyWith(
      selectedMedia: List.unmodifiable(
        state.selectedMedia.where((item) => !mediaIds.contains(item.id)),
      ),
      selectedImageFits: Map.unmodifiable(fits),
      selectedCropTransforms: Map.unmodifiable(transforms),
    );
    _syncTimelineMedia();
  }

  void clearSelection() {
    ref.read(appLoggerProvider).info(_tag, 'Clearing editor media selection');
    state = const EditorMediaSelectionState.initial();
    _syncTimelineMedia();
  }

  void _syncTimelineMedia() {
    ref
        .read(timelineViewModelProvider.notifier)
        .syncSelectedMediaToMarkers(
          selectedMedia: state.selectedMedia,
          selectedImageFits: state.selectedImageFits,
          selectedCropTransforms: state.selectedCropTransforms,
        );
  }
}
