import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';

class TimelineState {
  const TimelineState({
    required this.project,
    required this.serializedProject,
    required this.selectedMarker,
    required this.nextQueuedMediaIndex,
    required this.selectedTemplate,
  });

  const TimelineState.initial()
    : project = null,
      serializedProject = null,
      selectedMarker = null,
      nextQueuedMediaIndex = 0,
      selectedTemplate = VideoTemplates.cleanMemories;

  final ProjectTimeline? project;
  final Map<String, Object?>? serializedProject;
  final TimelineMarkerSelection? selectedMarker;
  final int nextQueuedMediaIndex;
  final VideoTemplate selectedTemplate;

  bool get hasProject => project != null;
  bool get hasSelectedMarker => selectedMarker != null;

  TimelineState copyWith({
    ProjectTimeline? project,
    Map<String, Object?>? serializedProject,
    TimelineMarkerSelection? selectedMarker,
    int? nextQueuedMediaIndex,
    VideoTemplate? selectedTemplate,
    bool clearSelectedMarker = false,
  }) {
    return TimelineState(
      project: project ?? this.project,
      serializedProject: serializedProject ?? this.serializedProject,
      selectedMarker: clearSelectedMarker
          ? null
          : selectedMarker ?? this.selectedMarker,
      nextQueuedMediaIndex: nextQueuedMediaIndex ?? this.nextQueuedMediaIndex,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}
