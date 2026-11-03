import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_captions_editor.dart';

void main() {
  testWidgets('editing a repeated photo dispatches the selected occurrence', (
    tester,
  ) async {
    MediaTrackClipPayload? edited;
    const first = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'Photo',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
    );
    final second = first.copyWith(
      clipId: 'two',
      start: const Duration(seconds: 3),
      end: const Duration(seconds: 6),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ClipCaptionsEditor(
              clips: [first, second],
              onEditClip: (clip) => edited = clip,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Clip 2: Photo'),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Edit clip'),
      ),
    );
    expect(edited?.clipId, 'two');
    expect(find.byType(AlertDialog), findsNothing);
  });
}
