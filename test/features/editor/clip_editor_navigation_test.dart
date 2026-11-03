import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_test_helpers.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/commons/navigation/screen_factory.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/clips_tab_view.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  testWidgets('clip list and queued image open the same editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final item = LibraryMediaItem(
      id: 'one',
      title: 'Photo',
      tagline: '',
      sizeLabel: '',
      importedOnLabel: '',
      importedOn: DateTime(2026),
      byteLength: 0,
      thumbnailBytes: Uint8List(0),
      sourcePath: '',
    );
    container
        .read(editorMediaSelectionViewModelProvider.notifier)
        .addMedia(item);
    container
        .read(timelineViewModelProvider.notifier)
        .appendQueuedMedia(
          items: [item],
          imageFits: const {},
          cropTransforms: const {},
        );
    final clip = container
        .read(timelineViewModelProvider)
        .value!
        .project!
        .tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .single;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          onGenerateRoute: ScreenFactory.onGenerateRoute,
          home: Scaffold(
            body: ClipsTabView(
              showTimelineClips: true,
              timelineClips: [clip],
              selectedMedia: [item],
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
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit clip'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageSettingsScreen), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queued images (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adjust crop'));
    await tester.tap(find.text('Adjust crop'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageSettingsScreen), findsOneWidget);
  });
  testWidgets('switching tools restores each scroll position', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final item = LibraryMediaItem(
      id: 'one',
      title: 'one',
      tagline: '',
      sizeLabel: '',
      importedOnLabel: '',
      importedOn: DateTime(2026),
      byteLength: 0,
      thumbnailBytes: Uint8List(0),
      sourcePath: '',
    );
    container
        .read(timelineViewModelProvider.notifier)
        .appendQueuedMedia(
          items: [item],
          imageFits: const {},
          cropTransforms: const {},
        );
    final clip = container
        .read(timelineViewModelProvider)
        .value!
        .project!
        .tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .single;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          onGenerateRoute: ScreenFactory.onGenerateRoute,
          home: Scaffold(
            body: TextButton(
              onPressed: () =>
                  AppNavigator.instance.goToImageSettings(clip.clipId),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final cropList = find.byKey(
      const PageStorageKey(ImageSettingsSection.framing),
    );
    await tester.drag(cropList, const Offset(0, -350));
    await tester.pumpAndSettle();
    double offset() => tester
        .state<ScrollableState>(
          find
              .descendant(of: cropList, matching: find.byType(Scrollable))
              .first,
        )
        .position
        .pixels;
    final previousOffset = offset();
    expect(previousOffset, greaterThan(0));
    await tester.ensureVisible(find.text('Motion').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motion').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey(ImageSettingsSection.motion)),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Crop').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crop').first);
    await tester.pumpAndSettle();
    expect(offset(), closeTo(previousOffset, 1));
  });
  for (final size in [const Size(390, 844), const Size(1024, 900)]) {
    testWidgets('editor shares draft and cancellation at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = createEditorTestContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      final item = LibraryMediaItem(
        id: 'one',
        title: 'one',
        tagline: '',
        sizeLabel: '',
        importedOnLabel: '',
        importedOn: DateTime(2026),
        byteLength: 0,
        thumbnailBytes: Uint8List(0),
        sourcePath: '',
      );
      container
          .read(timelineViewModelProvider.notifier)
          .appendQueuedMedia(
            items: [item],
            imageFits: const {},
            cropTransforms: const {},
          );
      MediaTrackClipPayload clip() => container
          .read(timelineViewModelProvider)
          .value!
          .project!
          .tracks
          .expand((track) => track.events)
          .map((event) => event.payload)
          .whereType<MediaTrackClipPayload>()
          .single;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: AppNavigator.instance.navigatorKey,
            onGenerateRoute: ScreenFactory.onGenerateRoute,
            home: Scaffold(
              body: TextButton(
                onPressed: () =>
                    AppNavigator.instance.goToImageSettings(clip().clipId),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Edit clip'), findsOneWidget);
      expect(
        find.byType(Dialog),
        size.width >= 600 ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Fit'));
      expect(clip().imageFit.name, 'cover');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(clip().imageFit.name, 'cover');
    });
  }
}
