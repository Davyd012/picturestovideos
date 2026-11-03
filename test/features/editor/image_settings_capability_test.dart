import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/image_settings_screen.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  testWidgets(
    'unavailable renderer features are disabled in the shared editor',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          renderCapabilitiesProvider.overrideWith(
            (ref) async => RenderCapabilities(
              platformSupported: true,
              ffmpegAvailable: true,
              filters: const {},
              encoders: const {},
              muxers: const {},
              videoEncoder: 'test',
            ),
          ),
        ],
      );
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
      final clip = container
          .read(timelineViewModelProvider)
          .value!
          .project!
          .tracks
          .expand((track) => track.events)
          .map((event) => event.payload)
          .whereType<MediaTrackClipPayload>()
          .first;
      Future<void> show(ImageSettingsSection section) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ImageSettingsScreen(
                key: ValueKey(section),
                args: ImageSettingsRouteArgs.forClip(
                  clip.clipId,
                  section: section,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(ImageSettingsSection.motion);
      expect(find.textContaining('Motion options are locked'), findsOneWidget);
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .every((chip) => chip.onSelected == null),
        isTrue,
      );
      await show(ImageSettingsSection.transition);
      expect(
        find.textContaining('Transition options are locked'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<ClipTransitionType?>>(
              find.byType(DropdownButtonFormField<ClipTransitionType?>),
            )
            .onChanged,
        isNull,
      );
      await show(ImageSettingsSection.text);
      expect(find.textContaining('Caption editing is locked'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        isTrue,
      );
    },
  );
}
