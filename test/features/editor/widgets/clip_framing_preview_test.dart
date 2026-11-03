import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_preview.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

void main() {
  testWidgets('queued preview uses its in-memory thumbnail', (tester) async {
    final item = LibraryMediaItem(
      id: 'one',
      title: 'one',
      tagline: '',
      sizeLabel: '',
      importedOnLabel: '',
      importedOn: DateTime(2026),
      byteLength: 0,
      thumbnailBytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/aL8AAAAASUVORK5CYII=',
      ),
      sourcePath: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: ClipFramingPreview(
              item: item,
              sourcePath: '',
              fit: VideoTemplateImageFit.cover,
              crop: ImageCropTransform.centered,
              aspectRatio: 1.5,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });
  testWidgets('mouse wheel adjusts zoom', (tester) async {
    var crop = ImageCropTransform.centered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) => ClipFramingPreview(
                  sourcePath: '',
                  fit: VideoTemplateImageFit.cover,
                  crop: crop,
                  aspectRatio: 1.5,
                  onChanged: (value) => setState(() => crop = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(ClipFramingPreview)),
        scrollDelta: const Offset(0, -20),
      ),
    );
    await tester.pump();
    expect(crop.zoom, closeTo(1.1, 0.001));
  });
  testWidgets('pinching the preview changes zoom', (tester) async {
    var crop = ImageCropTransform.centered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) => ClipFramingPreview(
                  sourcePath: '',
                  fit: VideoTemplateImageFit.cover,
                  crop: crop,
                  aspectRatio: 1.5,
                  onChanged: (value) => setState(() => crop = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(ClipFramingPreview));
    final first = await tester.startGesture(
      center + const Offset(-30, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await first.moveBy(const Offset(-20, 0));
    await second.moveBy(const Offset(20, 0));
    await tester.pump();
    await first.moveBy(const Offset(-20, 0));
    await second.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(crop.zoom, greaterThan(1));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  });
  testWidgets('motion preview does not change crop when dragged', (
    tester,
  ) async {
    var crop = ImageCropTransform.centered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: ClipFramingPreview(
                sourcePath: '',
                fit: VideoTemplateImageFit.cover,
                crop: crop,
                aspectRatio: 1.5,
                editable: false,
                onChanged: (value) => crop = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ClipFramingPreview), const Offset(30, 0));
    await tester.pump();
    expect(crop, ImageCropTransform.centered);
  });
  testWidgets('dragging changes framing immediately and double tap resets', (
    tester,
  ) async {
    var crop = ImageCropTransform.centered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) => ClipFramingPreview(
                  sourcePath: '',
                  fit: VideoTemplateImageFit.cover,
                  crop: crop,
                  aspectRatio: 1.5,
                  onChanged: (value) => setState(() => crop = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ClipFramingPreview), const Offset(30, 0));
    await tester.pump();
    expect(crop.focalX, lessThan(0));
    await tester.tap(find.byType(ClipFramingPreview));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(ClipFramingPreview));
    await tester.pump();
    expect(crop, ImageCropTransform.centered);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
