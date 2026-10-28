import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

abstract interface class ProjectRepository {
  Future<List<ProjectTimeline>> loadAll();
  Future<void> save(ProjectTimeline project);
  List<ProjectStorageIssue> get lastLoadIssues;
}

class ProjectStorageIssue {
  const ProjectStorageIssue({
    required this.projectFile,
    required this.recoveredFromBackup,
  });

  final String projectFile;
  final bool recoveredFromBackup;
}
