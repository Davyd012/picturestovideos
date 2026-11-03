import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/clip_editor_controller.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test('transition scope saves every boundary and undo restores it', () async {
    final container = ProviderContainer();
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
    final seed = ClipEditorSeed(
      clips().first,
      VideoTemplateAspectRatio.landscape,
      ImageSettingsSection.transition,
    );
    final provider = clipEditorControllerProvider(seed);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);
    controller.transitionChanged(ClipTransitionType.slide);
    controller.transitionScopeChanged(ClipEditScope.all);
    final undo = controller.savePressed(hasNext: true);
    expect(
      clips()
          .take(2)
          .every((clip) => clip.transitionOverride == ClipTransitionType.slide),
      isTrue,
    );
    expect(clips().last.transitionOverride, isNull);
    undo!();
    expect(clips().every((clip) => clip.transitionOverride == null), isTrue);
  });
  test('draft changes and scopes stay separate from the source clip', () {
    const clip = MediaTrackClipPayload(
      mediaId: 'one',
      title: 'one',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 4),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    final seed = ClipEditorSeed(
      clip,
      VideoTemplateAspectRatio.landscape,
      ImageSettingsSection.framing,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = clipEditorControllerProvider(seed);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);
    controller.fitChanged(VideoTemplateImageFit.contain);
    controller.motionChanged(ClipMotionPreset.gentlePan);
    controller.motionScopeChanged(ClipEditScope.all);
    controller.captionChanged('New caption', 'Line');
    expect(container.read(provider).fit, VideoTemplateImageFit.contain);
    expect(container.read(provider).motion, ClipMotionPreset.gentlePan);
    expect(container.read(provider).motionScope, ClipEditScope.all);
    expect(container.read(provider).caption, 'New caption');
    expect(container.read(provider).dirty, isTrue);
    expect(clip.imageFit, VideoTemplateImageFit.cover);
    expect(clip.caption, isEmpty);
  });
}
