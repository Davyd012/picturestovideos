import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/clips_tab_view.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

class _Queue extends EditorMediaSelectionViewModel {
  _Queue(this.items);
  final List<LibraryMediaItem> items;

  @override
  EditorMediaSelectionState build() => EditorMediaSelectionState(
    selectedMedia: items,
    selectedImageFits: const {},
    selectedCropTransforms: const {},
    sequenceSort: StagedSequenceSort.custom,
    isSortAscending: true,
  );
}

void main() {
  for (final count in [0, 1, 56, 110]) {
    testWidgets('mobile queue displays $count items', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = File('test/fixtures/generated/square.png')
          .readAsBytesSync();
      final items = List.generate(
        count,
        (index) => LibraryMediaItem(
          id: '$index',
          title: '$index.png',
          tagline: '',
          sizeLabel: '',
          importedOnLabel: '',
          importedOn: DateTime(2026),
          byteLength: bytes.length,
          thumbnailBytes: bytes,
          sourcePath: '',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorMediaSelectionViewModelProvider.overrideWith(
              () => _Queue(items),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClipsTabView(
                selectedMedia: items,
                selectedImageFits: const {},
                selectedCropTransforms: const {},
                onReorderMedia: (_, _) {},
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
      await tester.tap(find.text('Queued images ($count)'));
      await tester.pumpAndSettle();
      expect(find.text('Queued images ($count)'), findsWidgets);
      if (count > 0) {
        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(Image), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
