import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

class EditorMediaSelectionState {
  const EditorMediaSelectionState({
    required this.selectedMedia,
    required this.selectedImageFits,
  });

  const EditorMediaSelectionState.initial()
    : selectedMedia = const [],
      selectedImageFits = const {};

  final List<LibraryMediaItem> selectedMedia;
  final Map<String, VideoTemplateImageFit> selectedImageFits;

  bool get hasSelection => selectedMedia.isNotEmpty;
  int get selectedCount => selectedMedia.length;

  bool containsMedia(String mediaId) {
    return selectedMedia.any((item) => item.id == mediaId);
  }

  VideoTemplateImageFit imageFitFor(String mediaId) {
    return selectedImageFits[mediaId] ?? VideoTemplateImageFit.cover;
  }

  EditorMediaSelectionState copyWith({
    List<LibraryMediaItem>? selectedMedia,
    Map<String, VideoTemplateImageFit>? selectedImageFits,
  }) {
    return EditorMediaSelectionState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      selectedImageFits: selectedImageFits ?? this.selectedImageFits,
    );
  }
}
