import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

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
  }

  void removeMedia(String mediaId) {
    ref
        .read(appLoggerProvider)
        .info(_tag, 'Removing media $mediaId from editor selection');
    state = state.copyWith(
      selectedMedia: List.unmodifiable(
        state.selectedMedia.where((item) => item.id != mediaId),
      ),
    );
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
  }

  void clearSelection() {
    ref.read(appLoggerProvider).info(_tag, 'Clearing editor media selection');
    state = const EditorMediaSelectionState.initial();
  }
}
