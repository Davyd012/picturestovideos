import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

void main() {
  test('sorts, reverses, and moves staged images', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final viewModel = container.read(
      editorMediaSelectionViewModelProvider.notifier,
    );
    viewModel.addAllMedia([
      _item('b', 'Beta.jpg', 1, DateTime(2026, 1, 2)),
      _item('a', 'Alpha.jpg', 0, DateTime(2026, 1, 3)),
      _item('c', 'Charlie.jpg', 2, DateTime(2026, 1, 1)),
    ]);

    viewModel.sortSequence(StagedSequenceSort.title);
    expect(
      container
          .read(editorMediaSelectionViewModelProvider)
          .selectedMedia
          .map((item) => item.id),
      ['a', 'b', 'c'],
    );

    viewModel.reverseSequence();
    viewModel.moveMediaToPosition(mediaId: 'a', position: 1);
    final state = container.read(editorMediaSelectionViewModelProvider);
    expect(state.selectedMedia.map((item) => item.id), ['a', 'c', 'b']);
    expect(state.sequenceSort, StagedSequenceSort.custom);
  });

  test('bulk fit and crop transform remain independently editable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final viewModel = container.read(
      editorMediaSelectionViewModelProvider.notifier,
    );
    viewModel.addAllMedia([
      _item('a', 'Alpha.jpg', 0, DateTime(2026)),
      _item('b', 'Beta.jpg', 1, DateTime(2026)),
    ]);

    viewModel.imageFitSelectedForAll(VideoTemplateImageFit.contain);
    viewModel.imageFitSelected(
      mediaId: 'a',
      imageFit: VideoTemplateImageFit.cover,
    );
    const transform = ImageCropTransform(focalX: 0.4, focalY: -0.2, zoom: 1.8);
    viewModel.cropTransformChanged(mediaId: 'a', transform: transform);

    final state = container.read(editorMediaSelectionViewModelProvider);
    expect(state.imageFitFor('a'), VideoTemplateImageFit.cover);
    expect(state.imageFitFor('b'), VideoTemplateImageFit.contain);
    expect(state.cropTransformFor('a'), transform);
  });
}

LibraryMediaItem _item(
  String id,
  String title,
  int importOrder,
  DateTime fileDate,
) {
  return LibraryMediaItem(
    id: id,
    title: title,
    sizeLabel: '1 MB',
    tagline: 'Imported image',
    importedOnLabel: 'Jan 01, 2026',
    importedOn: DateTime(2026),
    byteLength: 1024,
    thumbnailBytes: Uint8List(0),
    sourcePath: '',
    fileModifiedOn: fileDate,
    importOrder: importOrder,
  );
}
