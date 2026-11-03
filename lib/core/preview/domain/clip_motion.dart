import 'dart:math' as math;

import 'package:picturestovideos/core/templates/domain/video_template.dart';

enum ClipMotionPreset {
  none,
  slowZoomIn,
  slowZoomOut,
  gentlePan,
  gentlePanReverse;

  static ClipMotionPreset fromTemplate(VideoTemplateImageAnimation animation) =>
      switch (animation) {
        VideoTemplateImageAnimation.none => none,
        VideoTemplateImageAnimation.slowZoomOut ||
        VideoTemplateImageAnimation.softPopIn => slowZoomOut,
        VideoTemplateImageAnimation.slowZoomIn ||
        VideoTemplateImageAnimation.quickPunchZoom => slowZoomIn,
      };
}

enum ClipMotionIntensity { subtle, moreMovement }

/// Normalized movement parameters shared by the editing preview and renderer.
class ClipMotion {
  const ClipMotion({required this.preset, required this.intensity});
  final ClipMotionPreset preset;
  final ClipMotionIntensity intensity;

  double get amount => intensity == ClipMotionIntensity.subtle ? 0.08 : 0.16;
  double get startZoom => switch (preset) {
    ClipMotionPreset.slowZoomOut ||
    ClipMotionPreset.gentlePan ||
    ClipMotionPreset.gentlePanReverse => 1 + amount,
    _ => 1,
  };
  double get endZoom => switch (preset) {
    ClipMotionPreset.slowZoomIn ||
    ClipMotionPreset.gentlePan ||
    ClipMotionPreset.gentlePanReverse => 1 + amount,
    _ => 1,
  };
  double zoomAt(double progress) =>
      startZoom + (endZoom - startZoom) * progress.clamp(0, 1);

  /// The pan range shrinks near an edge, keeping the selected focal point visible.
  double horizontalAnchorAt(double progress, double focalX) {
    final anchor = ((focalX + 1) / 2).clamp(0.0, 1.0);
    if (preset != ClipMotionPreset.gentlePan &&
        preset != ClipMotionPreset.gentlePanReverse) {
      return anchor;
    }
    final range = math.min(anchor, 1 - anchor);
    final direction = preset == ClipMotionPreset.gentlePanReverse ? -1 : 1;
    return anchor + direction * (2 * progress.clamp(0, 1) - 1) * range;
  }
}
