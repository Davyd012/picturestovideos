import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_captions_editor.dart';

void main() {
  testWidgets('applies framing to the selected repeated clip', (tester) async {
    String? editedId;
    VideoTemplateImageFit? fit;
    ImageCropTransform? crop;
    const photo = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'photo.jpg',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: [
              photo,
              photo.copyWith(clipId: 'two'),
            ],
            onCaptionChanged: (_, _, _) {},
            onFramingChanged: (id, value, transform) {
              editedId = id;
              fit = value;
              crop = transform;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 2: photo.jpg'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Fill frame (crop)').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill frame (crop)').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Full image').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full image').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Full image').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full image').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill frame (crop)').last);
    await tester.pumpAndSettle();
    final zoom = tester.widget<Slider>(find.byType(Slider).first);
    zoom.onChanged!(2);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Center image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Center image'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider).first).value, 1);
    tester.widget<Slider>(find.byType(Slider).first).onChanged!(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(editedId, 'two');
    expect(fit, VideoTemplateImageFit.cover);
    expect(crop!.zoom, 2);
  });
  testWidgets('edits duration and can disable marker snapping', (tester) async {
    Duration? duration;
    bool? snap;
    const clip = MediaTrackClipPayload(
      clipId: 'first',
      mediaId: 'photo',
      title: 'Photo',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: const [clip],
            onCaptionChanged: (_, _, _) {},
            onTimingChanged: (_, value, shouldSnap) {
              duration = value;
              snap = shouldSnap;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 1: Photo'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clip duration (seconds)'),
      '4.25',
    );
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(duration, const Duration(milliseconds: 4250));
    expect(snap, isFalse);
  });
  testWidgets('canceling framing edits keeps the selected clip unchanged', (
    tester,
  ) async {
    var framingChanges = 0;
    const clip = MediaTrackClipPayload(
      clipId: 'occurrence',
      mediaId: 'photo',
      title: 'Photo',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: const [clip],
            onCaptionChanged: (_, _, _) {},
            onFramingChanged: (_, _, _) => framingChanges++,
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 1: Photo'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(framingChanges, 0);
  });
  testWidgets('transition controls warn when the next clip is too short', (
    tester,
  ) async {
    ClipTransitionType? selected;
    const first = MediaTrackClipPayload(
      clipId: 'first',
      mediaId: 'photo',
      title: 'Photo',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 2),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    final second = first.copyWith(
      clipId: 'second',
      start: const Duration(seconds: 2),
      end: const Duration(milliseconds: 2200),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: [first, second],
            template: VideoTemplates.cleanMemories,
            gateRenderCapabilities: true,
            renderCapabilities: _capableRenderer(),
            onCaptionChanged: (_, _, _) {},
            onTransitionChanged: (_, type, _) => selected = type,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 1: Photo'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The transition will be shortened to fit these clips.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Style default').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gentle slide').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(selected, ClipTransitionType.slide);
  });
  testWidgets('changes motion for a single clip', (tester) async {
    ClipMotionPreset? selected;
    ClipMotionIntensity? selectedIntensity;
    const photo = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'photo.jpg',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: const [photo],
            onCaptionChanged: (_, _, _) {},
            gateRenderCapabilities: true,
            renderCapabilities: _capableRenderer(),
            onMotionChanged: (_, preset, intensity) {
              selected = preset;
              selectedIntensity = intensity;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 1: photo.jpg'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Style default').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gentle pan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Style default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More movement').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(selected, ClipMotionPreset.gentlePan);
    expect(selectedIntensity, ClipMotionIntensity.moreMovement);
  });

  testWidgets('locks unsupported motion, transition and caption controls', (
    tester,
  ) async {
    const photo = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'photo.jpg',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    final capabilities = RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: {'scale', 'crop', 'pad'},
      encoders: {'libx264'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: [
              photo,
              photo.copyWith(clipId: 'two'),
            ],
            template: VideoTemplates.cleanMemories,
            gateRenderCapabilities: true,
            renderCapabilities: capabilities,
            onCaptionChanged: (_, _, _) {},
            onCaptionSettingsChanged: (_, _) {},
            onMotionChanged: (_, _, _) {},
            onTransitionChanged: (_, _, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 1: photo.jpg'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Caption editing is locked because text rendering or its font is unavailable.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Motion options are locked because this renderer does not support the required filter.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Transition options are locked because this renderer does not support the required filter.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
    await tester.ensureVisible(find.text('Timing').last);
    await tester.tap(find.text('Timing').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<ClipMotionPreset?>>(
            find.byType(DropdownButtonFormField<ClipMotionPreset?>),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<ClipTransitionType?>>(
            find.byType(DropdownButtonFormField<ClipTransitionType?>),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets('edits the selected occurrence of a repeated photo', (
    tester,
  ) async {
    String? editedId;
    String? caption;
    String? supportingLine;
    const photo = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'photo.jpg',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ProviderScope(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ClipCaptionsEditor(
            clips: [
              photo,
              photo.copyWith(clipId: 'two'),
            ],
            gateRenderCapabilities: true,
            renderCapabilities: _capableRenderer(),
            onCaptionChanged: (id, title, line) {
              editedId = id;
              caption = title;
              supportingLine = line;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 2: photo.jpg'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Sommer i Norge');
    await tester.enterText(find.byType(TextFormField).last, 'Привет!');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(editedId, 'two');
    expect(caption, 'Sommer i Norge');
    expect(supportingLine, 'Привет!');
  });
}

RenderCapabilities _capableRenderer() => RenderCapabilities(
  platformSupported: true,
  ffmpegAvailable: true,
  filters: {'scale', 'crop', 'pad', 'zoompan', 'xfade', 'drawtext', 'drawbox'},
  encoders: {'libx264', 'aac'},
  muxers: {'mp4'},
  videoEncoder: 'libx264',
  fontPath: 'font.ttf',
);
