import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';

enum EditorPreviewStatus { idle, live, rendering, ready, failure }

class EditorPreviewState {
  const EditorPreviewState({
    required this.status,
    required this.result,
    required this.signature,
    required this.renderedSignature,
    required this.errorMessage,
    required this.statusMessage,
  });

  const EditorPreviewState.initial()
    : status = EditorPreviewStatus.idle,
      result = null,
      signature = null,
      renderedSignature = null,
      errorMessage = null,
      statusMessage = null;

  final EditorPreviewStatus status;
  final BuildPreviewVideoResult? result;
  final String? signature;
  final String? renderedSignature;
  final String? errorMessage;
  final String? statusMessage;

  bool get isIdle => status == EditorPreviewStatus.idle;
  bool get isLive => status == EditorPreviewStatus.live;
  bool get isRendering => status == EditorPreviewStatus.rendering;
  bool get isReady => status == EditorPreviewStatus.ready && result != null;
  bool get hasRenderedResult => result != null;
  bool get isRenderedPreviewStale =>
      result != null && renderedSignature != signature;
  bool get isFailure => status == EditorPreviewStatus.failure;

  EditorPreviewState copyWith({
    EditorPreviewStatus? status,
    BuildPreviewVideoResult? result,
    String? signature,
    String? renderedSignature,
    String? errorMessage,
    String? statusMessage,
    bool clearResult = false,
    bool clearSignature = false,
    bool clearRenderedSignature = false,
    bool clearError = false,
    bool clearStatusMessage = false,
  }) {
    return EditorPreviewState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      signature: clearSignature ? null : signature ?? this.signature,
      renderedSignature: clearRenderedSignature
          ? null
          : renderedSignature ?? this.renderedSignature,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
    );
  }
}
