import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';

void main() {
  testWidgets('stale rendered preview explains how to refresh', (tester) async {
    const map = BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 1),
    );
    const previewState = EditorPreviewState(
      status: EditorPreviewStatus.live,
      result: BuildPreviewVideoResult(
        outputPath: 'old-render.mp4',
        signature: 'render-signature',
        totalDuration: Duration(seconds: 4),
        thumbnails: [],
      ),
      signature: 'current-edit-signature',
      renderedSignature: 'render-signature',
      errorMessage: null,
      statusMessage: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MobileEditorPreviewCard(
                beatMap: map,
                project: null,
                playback: const PlaybackState.initial(),
                previewState: previewState,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Editing preview'), findsOneWidget);
    expect(find.text('Rendered preview'), findsOneWidget);
    expect(
      find.text(
        'This rendered preview is out of date. Refresh it to include the latest edits.',
      ),
      findsOneWidget,
    );
    expect(find.text('Refresh rendered preview'), findsOneWidget);
  });

  testWidgets('caption preview follows selected clip portion while scrubbing', (
    tester,
  ) async {
    const map = BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 1),
    );
    const clip = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'photo',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 4),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
      caption: 'A memory',
      captionSettings: CaptionSettings(
        placement: CaptionPlacement.top,
        entrance: CaptionEntrance.fade,
        startFraction: 0.25,
        endFraction: 0.75,
      ),
    );
    const project = ProjectTimeline(
      id: 'p',
      name: 'P',
      beatMap: map,
      tracks: [
        TimelineTrack(
          id: 'track-media',
          name: 'Images',
          events: [
            BeatEvent(time: Duration.zero, type: 'image', payload: clip),
          ],
        ),
      ],
    );
    Widget app(Duration time) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MobileEditorPreviewCard(
              beatMap: map,
              project: project,
              playback: const PlaybackState.initial().copyWith(
                currentTime: time,
              ),
              previewState: const EditorPreviewState.initial(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(const Duration(milliseconds: 500)));
    expect(find.text('A memory'), findsNothing);
    await tester.pumpWidget(app(const Duration(seconds: 2)));
    expect(find.text('A memory'), findsOneWidget);
    await tester.pumpWidget(app(const Duration(milliseconds: 3500)));
    expect(find.text('A memory'), findsNothing);
  });
}
