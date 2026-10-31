import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/commons/navigation/app_navigator.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('image settings fit $size with keyboard and larger text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
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
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('image settings save edits to the selected clip', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
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
    await tester.drag(find.byType(Slider).first, const Offset(40, 0));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'New caption');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
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
