import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/editor_filmstrip.dart';

void main() {
  testWidgets('filmstrip selects and reorders timeline clips', (tester) async {
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
    int? from;
    int? to;
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
              onAdd: () {},
              onReorder: (a, b) {
                from = a;
                to = b;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('0')));
    expect(selected, '0');
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('0'))),
    );
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('1'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(from, 0);
    expect(to, 1);
  });
}
