import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/clips_tab_view.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

void main() {
  testWidgets('clips tab exposes reorder item callback', (tester) async {
    int? oldIndex;
    int? newIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipsTabView(
              selectedMedia: [
                _mediaItem(id: 'first', title: 'First.png'),
                _mediaItem(id: 'second', title: 'Second.png'),
                _mediaItem(id: 'third', title: 'Third.png'),
              ],
              selectedImageFits: const {},
              selectedCropTransforms: const {},
              onReorderMedia: (oldValue, newValue) {
                oldIndex = oldValue;
                newIndex = newValue;
              },
              onImageFitSelected: (_, _) {},
              onCropTransformChanged: (_, _) {},
              onApplyImageFitToAll: (_) {},
              onMoveMediaToPosition: (_, _) {},
              onOpenTimeline: () {},
            ),
          ),
        ),
      ),
    );

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem
        ?.call(0, 2);

    expect(oldIndex, 0);
    expect(newIndex, 2);
  });

  testWidgets('clips tab changes image fit per item', (tester) async {
    String? mediaId;
    VideoTemplateImageFit? imageFit;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipsTabView(
              selectedMedia: [_mediaItem(id: 'first', title: 'First.png')],
              selectedImageFits: const {'first': VideoTemplateImageFit.cover},
              selectedCropTransforms: const {},
              onReorderMedia: (_, _) {},
              onImageFitSelected: (id, fit) {
                mediaId = id;
                imageFit = fit;
              },
              onCropTransformChanged: (_, _) {},
              onApplyImageFitToAll: (_) {},
              onMoveMediaToPosition: (_, _) {},
              onOpenTimeline: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fill frame (crop)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full image').last);
    await tester.pumpAndSettle();

    expect(mediaId, 'first');
    expect(imageFit, VideoTemplateImageFit.contain);
  });

  testWidgets('clips tab moves an image to a numbered position', (
    tester,
  ) async {
    String? mediaId;
    int? position;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipsTabView(
              selectedMedia: [
                _mediaItem(id: 'first', title: 'First.png'),
                _mediaItem(id: 'second', title: 'Second.png'),
              ],
              selectedImageFits: const {},
              selectedCropTransforms: const {},
              onReorderMedia: (_, _) {},
              onImageFitSelected: (_, _) {},
              onCropTransformChanged: (_, _) {},
              onApplyImageFitToAll: (_) {},
              onMoveMediaToPosition: (id, nextPosition) {
                mediaId = id;
                position = nextPosition;
              },
              onOpenTimeline: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Move to position').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    expect(mediaId, 'first');
    expect(position, 2);
  });
}

LibraryMediaItem _mediaItem({required String id, required String title}) {
  return LibraryMediaItem(
    id: id,
    title: title,
    sizeLabel: '1 MB',
    tagline: 'Imported image',
    importedOnLabel: 'Jun 09, 2026',
    importedOn: DateTime(2026, 6, 9),
    byteLength: 1000000,
    thumbnailBytes: Uint8List(0),
    sourcePath: '',
  );
}
