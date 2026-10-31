import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_state.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/queue_screen.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

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
  for (final count in [0, 1, 110]) {
    testWidgets('queue displays $count images at phone width', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = File('test/fixtures/generated/square.png')
          .readAsBytesSync();
      final items = List.generate(
        count,
        (i) => LibraryMediaItem(
          id: '$i',
          title: '$i.png',
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const QueueScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Queued images'), findsOneWidget);
      if (count > 0) {
        expect(find.byType(Image), findsWidgets);
      }
      if (count > 1) {
        await tester.drag(find.byType(GridView), const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(find.text('Add selected (0)'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('queue selects, clears and adds real items once', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = File('test/fixtures/generated/square.png').readAsBytesSync();
    final items = List.generate(
      56,
      (i) => LibraryMediaItem(
        id: '$i',
        title: '$i.png',
        tagline: '',
        sizeLabel: '',
        importedOnLabel: '',
        importedOn: DateTime(2026),
        byteLength: bytes.length,
        thumbnailBytes: bytes,
        sourcePath: '',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        editorMediaSelectionViewModelProvider.overrideWith(() => _Queue(items)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: const QueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Add selected (0)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('0')));
    await tester.pump();
    expect(find.text('Add selected (1)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('Add selected (56)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('Add selected (0)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('0')));
    await tester.pump();
    await tester.tap(find.text('Add selected (1)'));
    await tester.pumpAndSettle();
    final project = container.read(timelineViewModelProvider).value!.project!;
    final clips = project.tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();
    expect(clips.map((clip) => clip.mediaId), ['0']);
  });
}
