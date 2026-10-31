import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_list.dart';

void main() {
  testWidgets(
    'dragging clip 56 onto clip 55 reports the adjusted 1-based slot',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final clips = List.generate(56, _clip);
      String? movedId;
      int? destination;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipCaptionList(
                  clips: clips,
                  onEdit: (_, _) {},
                  onMove: (_, _) => true,
                  onReorder: (id, position) {
                    movedId = id;
                    destination = position;
                    return true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reorder'));
      await tester.pumpAndSettle();

      final list = find.byType(ReorderableListView);
      await tester.drag(list, const Offset(0, -10000));
      await tester.pumpAndSettle();

      final finalClipHandle = find.byIcon(Icons.drag_handle).last;
      await tester.drag(finalClipHandle, const Offset(0, -96));
      await tester.pumpAndSettle();

      expect(movedId, 'clip-56');
      expect(destination, 55);
    },
  );
}

MediaTrackClipPayload _clip(int index) => MediaTrackClipPayload(
  clipId: 'clip-${index + 1}',
  mediaId: 'media-${index + 1}',
  title: 'Image ${index + 1}',
  tagline: '',
  start: Duration(seconds: index * 3),
  end: Duration(seconds: (index + 1) * 3),
  sourcePath: '',
  imageFit: VideoTemplateImageFit.cover,
);
