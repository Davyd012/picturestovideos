import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/projects/saved_projects_section.dart';

void main() {
  testWidgets('shows a localized warning for recovered project storage', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(_RepositoryWithIssue()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const Scaffold(body: SavedProjectsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Some saved projects could not be read. Available projects are still listed, and a previous save was restored where possible.',
      ),
      findsOneWidget,
    );
  });
}

class _RepositoryWithIssue implements ProjectRepository {
  @override
  List<ProjectStorageIssue> get lastLoadIssues => const [
    ProjectStorageIssue(projectFile: 'project.json', recoveredFromBackup: true),
  ];

  @override
  Future<List<ProjectTimeline>> loadAll() async => const [];

  @override
  Future<void> save(ProjectTimeline project) async {}
}
