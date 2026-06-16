import 'package:picturestovideos/features/library/library_media_item.dart';

class EditorMediaSelectionState {
  const EditorMediaSelectionState({required this.selectedMedia});

  const EditorMediaSelectionState.initial() : selectedMedia = const [];

  final List<LibraryMediaItem> selectedMedia;

  bool get hasSelection => selectedMedia.isNotEmpty;
  int get selectedCount => selectedMedia.length;

  bool containsMedia(String mediaId) {
    return selectedMedia.any((item) => item.id == mediaId);
  }

  EditorMediaSelectionState copyWith({List<LibraryMediaItem>? selectedMedia}) {
    return EditorMediaSelectionState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
    );
  }
}
