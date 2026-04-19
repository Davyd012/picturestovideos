import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/editor/audio_editor_screen.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  testWidgets('audio editor shows empty guidance with no beat-aware data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AudioEditorScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editor waiting for beat-aware data'), findsOneWidget);
    expect(find.text('Go to import'), findsOneWidget);
  });

  testWidgets('audio editor renders timeline details when data is loaded', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const beatMap = BeatMap(
      beats: [
        Beat(time: Duration(milliseconds: 200), strength: 1.6),
        Beat(time: Duration(milliseconds: 700), strength: 1.4),
        Beat(time: Duration(milliseconds: 1200), strength: 1.8),
      ],
      bpm: 120,
      averageBeatInterval: Duration(milliseconds: 500),
    );

    await container.read(beatMapViewModelProvider.future);
    await container
        .read(beatMapViewModelProvider.notifier)
        .buildBeatMap(beatMap.beats);

    await container.read(eventSystemViewModelProvider.future);
    await container
        .read(eventSystemViewModelProvider.notifier)
        .loadMarkerEventsFromBeatMap(beatMap);

    await container.read(playbackViewModelProvider.future);
    await container
        .read(playbackViewModelProvider.notifier)
        .loadBeatMap(beatMap);
    await container
        .read(playbackViewModelProvider.notifier)
        .step(const Duration(milliseconds: 700));

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: beatMap,
          events: container.read(eventSystemViewModelProvider).value!.events,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AudioEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live preview'), findsOneWidget);
    expect(find.text('Timeline workspace'), findsOneWidget);
    expect(find.text('Markers'), findsOneWidget);
    expect(find.textContaining('120.0 BPM'), findsOneWidget);
  });
}
