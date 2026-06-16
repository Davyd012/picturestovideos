import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
              onReorderMedia: (oldValue, newValue) {
                oldIndex = oldValue;
                newIndex = newValue;
              },
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
