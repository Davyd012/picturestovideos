import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_test_helpers.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_preview.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  testWidgets('all transition scope confirms and undoes boundary edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    LibraryMediaItem item(String id) => LibraryMediaItem(
      id: id,
      title: id,
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
          items: [item('one'), item('two'), item('three')],
          imageFits: const {},
          cropTransforms: const {},
        );
    List<MediaTrackClipPayload> clips() => container
        .read(timelineViewModelProvider)
        .value!
        .project!
        .tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(
            args: ImageSettingsRouteArgs.forClip(
              clips().first.clipId,
              section: ImageSettingsSection.transition,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<ClipTransitionType?>>(
          find.byType(DropdownButtonFormField<ClipTransitionType?>),
        )
        .onChanged!(ClipTransitionType.slide);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('All transitions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All transitions'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      clips().take(2).every((clip) => clip.transitionOverride == null),
      isTrue,
    );
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(
      clips().take(2).every((clip) => clip.transitionOverride == null),
      isTrue,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      clips()
          .take(2)
          .every((clip) => clip.transitionOverride == ClipTransitionType.slide),
      isTrue,
    );
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(clips().every((clip) => clip.transitionOverride == null), isTrue);
  });
  testWidgets('caption text scope copies text and supports undo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    LibraryMediaItem item(String id) => LibraryMediaItem(
      id: id,
      title: id,
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
          items: [item('one'), item('two')],
          imageFits: const {},
          cropTransforms: const {},
        );
    List<MediaTrackClipPayload> clips() => container
        .read(timelineViewModelProvider)
        .value!
        .project!
        .tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(
            args: ImageSettingsRouteArgs.forClip(
              clips().first.clipId,
              section: ImageSettingsSection.text,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'Shared caption');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All images'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(clips().last.caption, isEmpty);
    await tester.tap(find.text('Apply').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(clips().every((clip) => clip.caption == 'Shared caption'), isTrue);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(clips().every((clip) => clip.caption.isEmpty), isTrue);
  });
  testWidgets(
    'transition edits are drafted and saved for the selected boundary',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = createEditorTestContainer();
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      LibraryMediaItem item(String id) => LibraryMediaItem(
        id: id,
        title: id,
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
            items: [item('one'), item('two')],
            imageFits: const {},
            cropTransforms: const {},
          );
      List<MediaTrackClipPayload> clips() => container
          .read(timelineViewModelProvider)
          .value!
          .project!
          .tracks
          .expand((track) => track.events)
          .map((event) => event.payload)
          .whereType<MediaTrackClipPayload>()
          .toList();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: AppNavigator.instance.navigatorKey,
            home: ImageSettingsScreen(
              args: ImageSettingsRouteArgs.forClip(
                clips().first.clipId,
                section: ImageSettingsSection.transition,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<ClipTransitionType?>>(
            find.byType(DropdownButtonFormField<ClipTransitionType?>),
          )
          .onChanged!(ClipTransitionType.slide);
      await tester.pump();
      expect(clips().first.transitionOverride, isNull);
      expect(find.text('Transition preview'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(clips().first.transitionOverride, ClipTransitionType.slide);
      expect(clips().last.transitionOverride, isNull);
    },
  );
  testWidgets('queued framing can be applied to all and undone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    LibraryMediaItem item(String id) => LibraryMediaItem(
      id: id,
      title: id,
      tagline: '',
      sizeLabel: '',
      importedOnLabel: '',
      importedOn: DateTime(2026),
      byteLength: 0,
      thumbnailBytes: Uint8List(0),
      sourcePath: '',
    );
    container.read(editorMediaSelectionViewModelProvider.notifier).addAllMedia([
      item('one'),
      item('two'),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(
            args: const ImageSettingsRouteArgs.forQueuedMedia('one'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All images'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      container.read(editorMediaSelectionViewModelProvider).imageFitFor('two'),
      VideoTemplateImageFit.contain,
    );
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(
      container.read(editorMediaSelectionViewModelProvider).imageFitFor('two'),
      VideoTemplateImageFit.cover,
    );
  });
  testWidgets('bulk framing is confirmed and can be undone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    LibraryMediaItem item(String id) => LibraryMediaItem(
      id: id,
      title: id,
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
          items: [item('one'), item('two')],
          imageFits: const {},
          cropTransforms: const {},
        );
    List<MediaTrackClipPayload> clips() => container
        .read(timelineViewModelProvider)
        .value!
        .project!
        .tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(clipId: clips().first.clipId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All images'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      clips().every((clip) => clip.imageFit == VideoTemplateImageFit.cover),
      isTrue,
    );
    await tester.tap(find.text('Apply').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      clips().every((clip) => clip.imageFit == VideoTemplateImageFit.contain),
      isTrue,
    );
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(
      clips().every((clip) => clip.imageFit == VideoTemplateImageFit.cover),
      isTrue,
    );
  });
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(390, 844),
  ]) {
    testWidgets('image settings fit $size with keyboard and larger text', (
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
      final project = container.read(timelineViewModelProvider).value!.project!;
      final clip = project.tracks
          .expand((track) => track.events)
          .map((event) => event.payload)
          .whereType<MediaTrackClipPayload>()
          .single;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
                viewInsets: const EdgeInsets.only(bottom: 180),
              ),
              child: child!,
            ),
            home: ImageSettingsScreen(clipId: clip.clipId),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
      if (size.height == 844) {
        expect(find.byType(ClipFramingPreview), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('queued image settings save before timeline insertion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = createEditorTestContainer();
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    final item = LibraryMediaItem(
      id: 'pending',
      title: 'pending.png',
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(
            args: const ImageSettingsRouteArgs.forQueuedMedia('pending'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final selection = container.read(editorMediaSelectionViewModelProvider);
    expect(selection.imageFitFor('pending'), VideoTemplateImageFit.contain);
    expect(selection.selectedMedia, hasLength(1));
  });
  testWidgets('image settings save edits to the selected clip', (tester) async {
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
    final project = container.read(timelineViewModelProvider).value!.project!;
    final clip = project.tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .single;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.instance.navigatorKey,
          home: ImageSettingsScreen(clipId: clip.clipId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fit'));
    await tester.pump();
    await tester.ensureVisible(find.text('1:1'));
    await tester.tap(find.text('1:1'));
    await tester.ensureVisible(find.text('Text').first);
    await tester.tap(find.text('Text').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'New caption');
    await tester.ensureVisible(find.text('Motion').first);
    await tester.tap(find.text('Motion').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('None').first);
    await tester.tap(find.text('None').first);
    await tester.ensureVisible(find.text('Display duration').first);
    await tester.tap(find.text('Display duration').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider).first, const Offset(40, 0));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final result = container.read(timelineViewModelProvider).value!.project!;
    final updated = result.tracks
        .expand((track) => track.events)
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .single;
    expect(updated.caption, 'New caption');
    expect(updated.imageFit, VideoTemplateImageFit.contain);
    expect(result.template.aspectRatio, VideoTemplateAspectRatio.square);
    expect(updated.end - updated.start, isNot(clip.end - clip.start));
    expect(updated.motionFor(result.template).preset, ClipMotionPreset.none);
  });
}
