import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_marker_payload.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/editor/widgets/markers_tab_view.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';

void main() {
  testWidgets(
    'selected marker controls fit above the list at large text size',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          child: _markers(
            selectedMarker: const TimelineMarkerSelection(
              time: Duration(seconds: 1),
              markerId: 'marker-1',
            ),
          ),
          locale: const Locale('ru'),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Маркер 1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Маркер 1')).dy,
        lessThan(tester.getTopLeft(find.byType(ListTile).first).dy),
      );
    },
  );

  testWidgets('deleting a marker row does not select or seek it', (
    tester,
  ) async {
    Duration? deletedTime;
    var selectionCount = 0;
    var undoNotices = 0;
    await tester.pumpWidget(
      _app(
        child: _markers(
          onMarkerDeletedAt: (time) => deletedTime = time,
          onMarkerSelected: (_) => selectionCount++,
          onUndoAvailable: () => undoNotices++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();

    expect(deletedTime, const Duration(seconds: 1));
    expect(selectionCount, 0);
    expect(undoNotices, 1);
  });
}

Widget _app({
  required Widget child,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget _markers({
  TimelineMarkerSelection? selectedMarker,
  ValueChanged<Duration>? onMarkerDeletedAt,
  ValueChanged<Duration>? onMarkerSelected,
  VoidCallback? onUndoAvailable,
}) => MarkersTabView(
  project: _project,
  selectedMarker: selectedMarker,
  onAddMarker: () {},
  onDeleteMarker: () {},
  onDeleteMarkerAtCurrentPoint: () {},
  onClearMarkers: () {},
  canSaveMarkerPreset: false,
  onSaveMarkerPreset: () {},
  onMarkerSelected: onMarkerSelected ?? (_) {},
  onMarkerDeletedAt: onMarkerDeletedAt,
  onUndoAvailable: onUndoAvailable,
  onMarkerTimeChanged: (_) {},
);

const _project = ProjectTimeline(
  id: 'project',
  name: 'Project',
  beatMap: BeatMap(beats: [], bpm: 0, averageBeatInterval: Duration.zero),
  tracks: [
    TimelineTrack(
      id: 'track-markers',
      name: 'Markers',
      events: [
        BeatEvent(
          time: Duration(seconds: 1),
          type: 'marker',
          payload: TimelineMarkerPayload(id: 'marker-1'),
        ),
        BeatEvent(
          time: Duration(seconds: 3),
          type: 'marker',
          payload: TimelineMarkerPayload(id: 'marker-2'),
        ),
      ],
    ),
  ],
);
