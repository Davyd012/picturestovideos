import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/editor/widgets/markers_tab_view.dart';
import 'package:picturestovideos/features/editor/widgets/timeline_tab_view.dart';

void main() {
  testWidgets('markers tab keeps cleared project markers visually empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkersTabView(
              beatMap: _beatMap,
              project: _emptyMarkerProject,
              events: _generatedEvents,
              selectedMarker: null,
              onAddMarker: () {},
              onDeleteMarker: () {},
              onDeleteMarkerAtCurrentPoint: () {},
              onClearMarkers: () {},
              canSaveMarkerPreset: false,
              onSaveMarkerPreset: () {},
              onMarkerSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 beat markers'), findsOneWidget);
    expect(find.text('Marker 1'), findsNothing);
    expect(find.text('B1'), findsNothing);
  });

  testWidgets('timeline tab keeps cleared project markers visually empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TimelineTabView(
              beatMap: _beatMap,
              project: _emptyMarkerProject,
              playback: null,
              timelineScale: 1,
              selectedMedia: const [],
              events: _generatedEvents,
              onTimelineScaleChanged: (_) {},
              onCurrentPointChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 markers'), findsOneWidget);
    expect(find.text('B1'), findsNothing);
  });
}

const _beatMap = BeatMap(
  beats: [
    Beat(time: Duration(milliseconds: 500), strength: 1),
    Beat(time: Duration(milliseconds: 1000), strength: 1),
  ],
  bpm: 120,
  averageBeatInterval: Duration(milliseconds: 500),
);

const _generatedEvents = [
  BeatEvent(time: Duration(milliseconds: 500), type: 'marker', payload: 'B1'),
  BeatEvent(time: Duration(milliseconds: 1000), type: 'marker', payload: 'B2'),
];

const _emptyMarkerProject = ProjectTimeline(
  id: 'project-main',
  name: 'Picture To Videos Project',
  beatMap: _beatMap,
  tracks: [
    TimelineTrack(id: 'track-markers', name: 'Markers', events: []),
    TimelineTrack(id: 'track-media', name: 'Images', events: []),
  ],
  template: VideoTemplates.cleanMemories,
);
