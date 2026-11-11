import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';
import 'package:picturestovideos/features/editor/audio_editor_screen.dart';
import 'package:picturestovideos/features/editor/mobile_editor_screen.dart';
import 'package:picturestovideos/features/editor/widgets/playback_controls.dart';

void main() {
  testWidgets('mobile marker entry opens the marker editor with playback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final player = ManualAudioPlayerRepository();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerRepositoryProvider.overrideWithValue(player),
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
        child: const MaterialApp(home: AudioEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Markers'));
    await tester.pumpAndSettle();

    expect(find.text('Add marker'), findsOneWidget);
    expect(find.byType(PlaybackControls), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final hasClip in [false, true]) {
    testWidgets(
      'mobile editor opens markers ${hasClip ? 'with' : 'without'} images',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final player = ManualAudioPlayerRepository();
        addTearDown(player.dispose);
        EditorTab? openedTab;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              audioPlayerRepositoryProvider.overrideWithValue(player),
            ],
            child: MaterialApp(
              home: MobileEditorScreen(
                project: hasClip ? _project : null,
                beatMap: hasClip ? _beatMap : null,
                audioPath: null,
                queueCount: 0,
                canExport: hasClip,
                openAdvanced: (tab) => openedTab = tab,
              ),
            ),
          ),
        );
        await tester.pump();

        final entry = find.text('Markers');
        expect(entry, findsOneWidget);
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        expect(openedTab, EditorTab.markers);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

const _beatMap = BeatMap(
  beats: [],
  bpm: 0,
  averageBeatInterval: Duration(seconds: 2),
);

const _project = ProjectTimeline(
  id: 'project',
  name: 'Project',
  beatMap: _beatMap,
  tracks: [
    TimelineTrack(
      id: 'track-media',
      name: 'Images',
      events: [
        BeatEvent(
          time: Duration.zero,
          type: 'image',
          payload: MediaTrackClipPayload(
            clipId: 'clip',
            mediaId: 'image',
            title: 'Image',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 4),
            sourcePath: '',
            imageFit: VideoTemplateImageFit.cover,
          ),
        ),
      ],
    ),
  ],
);
