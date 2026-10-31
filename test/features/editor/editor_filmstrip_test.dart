import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/editor_filmstrip.dart';

void main() {
  testWidgets('filmstrip selects, edits and exposes drag handles', (
    tester,
  ) async {
    final clips = List.generate(
      2,
      (i) => MediaTrackClipPayload(
        mediaId: '$i',
        clipId: '$i',
        title: '$i',
        tagline: '',
        start: Duration(seconds: i * 4),
        end: Duration(seconds: (i + 1) * 4),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      ),
    );
    String? selected;
    String? edited;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 180,
            child: EditorFilmstrip(
              clips: clips,
              selectedId: null,
              current: Duration.zero,
              audioPath: null,
              onSelect: (clip) => selected = clip.clipId,
              onEditClip: (clip) => edited = clip.clipId,
              onAdd: () {},
              onReorder: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('0')));
    expect(selected, '0');
    await tester.pumpAndSettle();
    final editGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('0'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await editGesture.up();
    await tester.pumpAndSettle();
    expect(edited, '0');
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));
  });
}
