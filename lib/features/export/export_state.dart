import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

enum ExportStatus {
  idle,
  validating,
  rendering,
  cancelling,
  cancelled,
  ready,
  saving,
  saved,
  sharing,
  failure,
}

class ExportState {
  const ExportState({
    required this.status,
    required this.statusMessage,
    this.result,
    this.errorMessage,
    this.capabilityIssue,
    this.renderProgress,
    this.project,
  });

  const ExportState.initial()
    : status = ExportStatus.idle,
      statusMessage = 'Export is waiting for a ready timeline.',
      result = null,
      errorMessage = null,
      capabilityIssue = null,
      renderProgress = null,
      project = null;

  final ExportStatus status;
  final String statusMessage;
  final BuildPreviewVideoResult? result;
  final String? errorMessage;
  final RenderCapabilityIssue? capabilityIssue;
  final BuildPreviewVideoProgress? renderProgress;
  final ProjectTimeline? project;

  bool get isRendering =>
      status == ExportStatus.rendering || status == ExportStatus.cancelling;
  bool get isValidating => status == ExportStatus.validating;
  bool get isCancelling => status == ExportStatus.cancelling;
  bool get isCancelled => status == ExportStatus.cancelled;
  bool get isReady =>
      status == ExportStatus.ready ||
      status == ExportStatus.saved ||
      status == ExportStatus.sharing;
  bool get isSaving => status == ExportStatus.saving;
  bool get isSharing => status == ExportStatus.sharing;
  bool get isFailure => status == ExportStatus.failure;
  bool get canSave => result != null && !isRendering && !isSaving && !isSharing;
  bool get canShare => canSave;
  bool get hasRenderProgress => isRendering && renderProgress != null;

  ExportState copyWith({
    ExportStatus? status,
    String? statusMessage,
    BuildPreviewVideoResult? result,
    String? errorMessage,
    RenderCapabilityIssue? capabilityIssue,
    BuildPreviewVideoProgress? renderProgress,
    ProjectTimeline? project,
    bool clearResult = false,
    bool clearError = false,
    bool clearRenderProgress = false,
  }) {
    return ExportState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      capabilityIssue: clearError
          ? null
          : capabilityIssue ?? this.capabilityIssue,
      renderProgress: clearRenderProgress
          ? null
          : renderProgress ?? this.renderProgress,
      project: project ?? this.project,
    );
  }
}
