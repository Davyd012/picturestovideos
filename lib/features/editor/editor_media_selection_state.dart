import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

enum StagedSequenceSort { custom, importOrder, title, fileDate }

class EditorMediaSelectionState {
  const EditorMediaSelectionState({
    required this.selectedMedia,
    required this.selectedImageFits,
    required this.selectedCropTransforms,
    required this.sequenceSort,
    required this.isSortAscending,
  });

  const EditorMediaSelectionState.initial()
    : selectedMedia = const [],
      selectedImageFits = const {},
      selectedCropTransforms = const {},
      sequenceSort = StagedSequenceSort.custom,
      isSortAscending = true;

  final List<LibraryMediaItem> selectedMedia;
  final Map<String, VideoTemplateImageFit> selectedImageFits;
  final Map<String, ImageCropTransform> selectedCropTransforms;
  final StagedSequenceSort sequenceSort;
  final bool isSortAscending;

  bool get hasSelection => selectedMedia.isNotEmpty;
  int get selectedCount => selectedMedia.length;

  bool containsMedia(String mediaId) {
    return selectedMedia.any((item) => item.id == mediaId);
  }

  VideoTemplateImageFit imageFitFor(String mediaId) {
    return selectedImageFits[mediaId] ?? VideoTemplateImageFit.cover;
  }

  ImageCropTransform cropTransformFor(String mediaId) {
    return selectedCropTransforms[mediaId] ?? ImageCropTransform.centered;
  }

  EditorMediaSelectionState copyWith({
    List<LibraryMediaItem>? selectedMedia,
    Map<String, VideoTemplateImageFit>? selectedImageFits,
    Map<String, ImageCropTransform>? selectedCropTransforms,
    StagedSequenceSort? sequenceSort,
    bool? isSortAscending,
  }) {
    return EditorMediaSelectionState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      selectedImageFits: selectedImageFits ?? this.selectedImageFits,
      selectedCropTransforms:
          selectedCropTransforms ?? this.selectedCropTransforms,
      sequenceSort: sequenceSort ?? this.sequenceSort,
      isSortAscending: isSortAscending ?? this.isSortAscending,
    );
  }
}
