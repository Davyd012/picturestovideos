import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

class TimelineState {
  const TimelineState({
    required this.project,
    required this.serializedProject,
  });

  const TimelineState.initial()
      : project = null,
        serializedProject = null;

  final ProjectTimeline? project;
  final Map<String, Object?>? serializedProject;

  bool get hasProject => project != null;
}
