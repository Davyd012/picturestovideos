import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';

enum ExportStatus { idle, rendering, ready, saving, saved, sharing, failure }

class ExportState {
  const ExportState({
    required this.status,
    required this.statusMessage,
    this.result,
    this.errorMessage,
  });

  const ExportState.initial()
    : status = ExportStatus.idle,
      statusMessage = 'Export is waiting for a ready timeline.',
      result = null,
      errorMessage = null;

  final ExportStatus status;
  final String statusMessage;
  final BuildPreviewVideoResult? result;
  final String? errorMessage;

  bool get isRendering => status == ExportStatus.rendering;
  bool get isReady =>
      status == ExportStatus.ready ||
      status == ExportStatus.saved ||
      status == ExportStatus.sharing;
  bool get isSaving => status == ExportStatus.saving;
  bool get isSharing => status == ExportStatus.sharing;
  bool get isFailure => status == ExportStatus.failure;
  bool get canSave => result != null && !isRendering && !isSaving && !isSharing;
  bool get canShare => canSave;

  ExportState copyWith({
    ExportStatus? status,
    String? statusMessage,
    BuildPreviewVideoResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ExportState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
