import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
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
    state = state.copyWith(
      selectedMedia: List.unmodifiable(
        state.selectedMedia.where((item) => item.id != mediaId),
      ),
      selectedImageFits: Map.unmodifiable(updatedFits),
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
    state = state.copyWith(selectedMedia: List.unmodifiable(selectedMedia));
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
        );
  }
}
