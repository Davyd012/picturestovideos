import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';

enum EditorPreviewStatus { idle, live, rendering, ready, failure }

class EditorPreviewState {
  const EditorPreviewState({
    required this.status,
    required this.result,
    required this.signature,
    required this.errorMessage,
    required this.statusMessage,
  });

  const EditorPreviewState.initial()
    : status = EditorPreviewStatus.idle,
      result = null,
      signature = null,
      errorMessage = null,
      statusMessage = null;

  final EditorPreviewStatus status;
  final BuildPreviewVideoResult? result;
  final String? signature;
  final String? errorMessage;
  final String? statusMessage;

  bool get isIdle => status == EditorPreviewStatus.idle;
  bool get isLive => status == EditorPreviewStatus.live;
  bool get isRendering => status == EditorPreviewStatus.rendering;
  bool get isReady => status == EditorPreviewStatus.ready && result != null;
  bool get isFailure => status == EditorPreviewStatus.failure;

  EditorPreviewState copyWith({
    EditorPreviewStatus? status,
    BuildPreviewVideoResult? result,
    String? signature,
    String? errorMessage,
    String? statusMessage,
    bool clearResult = false,
    bool clearSignature = false,
    bool clearError = false,
    bool clearStatusMessage = false,
  }) {
    return EditorPreviewState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      signature: clearSignature ? null : signature ?? this.signature,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
    );
  }
}
