import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/features/editor/widgets/tools_tab_view.dart';
import 'package:picturestovideos/features/projects/saved_projects_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  testWidgets('shows localized feedback when saving a project fails', (
    tester,
  ) async {
    const project = ProjectTimeline(
      id: 'project',
      name: 'Project',
      beatMap: BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 1),
      ),
      tracks: [],
    );
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(_FailingRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    container.read(timelineViewModelProvider.notifier).projectOpened(project);
    await container.read(savedProjectsViewModelProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: SingleChildScrollView(
              child: ToolsTabView(
                beatMap: null,
                project: project,
                playback: null,
                selectedTemplate: VideoTemplates.calmMemories,
                selectedMedia: const [],
                selectedImageFits: const {},
                selectedMarker: null,
                events: const <BeatEvent>[],
                eventStatusText: '',
                audioDuration: null,
                onAddMarker: _noop,
                onAddImagePoint: _noop,
                onDeleteMarker: _noop,
                onDeleteMarkerAtCurrentPoint: _noop,
                onClearMarkers: _noop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save project'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save the project'), findsOneWidget);
  });
}

void _noop() {}

class _FailingRepository implements ProjectRepository {
  @override
  List<ProjectStorageIssue> get lastLoadIssues => const [];

  @override
  Future<List<ProjectTimeline>> loadAll() async => const [];

  @override
  Future<void> save(ProjectTimeline project) async {
    throw StateError('private storage details');
  }
}
