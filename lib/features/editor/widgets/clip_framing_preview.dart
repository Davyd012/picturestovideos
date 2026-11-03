import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class ClipFramingPreview extends StatelessWidget {
  const ClipFramingPreview({
    required this.sourcePath,
    required this.fit,
    required this.crop,
    required this.aspectRatio,
    required this.onChanged,
    this.motion,
    this.editable = true,
    this.item,
    super.key,
  });
  final String sourcePath;
  final VideoTemplateImageFit fit;
  final ImageCropTransform crop;
  final double aspectRatio;
  final ValueChanged<ImageCropTransform> onChanged;
  final ClipMotionPreset? motion;
  final bool editable;
  final LibraryMediaItem? item;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(
        constraints.maxWidth,
        constraints.maxHeight * aspectRatio,
      );
      final height = width / aspectRatio;
      return Center(
        child: AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: SizedBox(
            width: width,
            height: height,
            child: _FramingGesture(
              crop: crop,
              width: width,
              height: height,
              editable: editable,
              canCrop: fit == VideoTemplateImageFit.cover,
              onChanged: onChanged,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: Transform.scale(
                        scale: fit == VideoTemplateImageFit.cover
                            ? crop.zoom
                            : 1,
                        alignment: Alignment(crop.focalX, crop.focalY),
                        child: MediaThumbnail(
                          item: item,
                          path: sourcePath,
                          fit: fit == VideoTemplateImageFit.cover
                              ? BoxFit.cover
                              : BoxFit.contain,
                          alignment: Alignment(crop.focalX, crop.focalY),
                        ),
                      ),
                    ),
                    if (motion != null && motion != ClipMotionPreset.none)
                      Center(
                        child: Material(
                          color: context.colors.surface,
                          shape: const StadiumBorder(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Icon(
                              switch (motion) {
                                ClipMotionPreset.gentlePan => Icons.east,
                                ClipMotionPreset.gentlePanReverse => Icons.west,
                                ClipMotionPreset.slowZoomIn => Icons.zoom_in,
                                ClipMotionPreset.slowZoomOut => Icons.zoom_out,
                                _ => Icons.motion_photos_off,
                              },
                              color: context.colors.primary,
                              semanticLabel: switch (motion) {
                                ClipMotionPreset.gentlePan =>
                                  context.l10n.motionPanForward,
                                ClipMotionPreset.gentlePanReverse =>
                                  context.l10n.motionPanReverse,
                                ClipMotionPreset.slowZoomIn =>
                                  context.l10n.motionZoomIn,
                                ClipMotionPreset.slowZoomOut =>
                                  context.l10n.motionZoomOut,
                                _ => context.l10n.motionNone,
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FramingGesture extends StatefulWidget {
  const _FramingGesture({
    required this.crop,
    required this.width,
    required this.height,
    required this.editable,
    required this.canCrop,
    required this.onChanged,
    required this.child,
  });
  final ImageCropTransform crop;
  final double width;
  final double height;
  final bool editable;
  final bool canCrop;
  final ValueChanged<ImageCropTransform> onChanged;
  final Widget child;
  @override
  State<_FramingGesture> createState() => _FramingGestureState();
}

class _FramingGestureState extends State<_FramingGesture> {
  late ImageCropTransform _startCrop;
  Offset _startPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.editable &&
        widget.canCrop &&
        widget.width > 0 &&
        widget.height > 0;
    return Listener(
      onPointerSignal: enabled
          ? (event) {
              if (event is PointerScrollEvent) {
                widget.onChanged(
                  widget.crop.copyWith(
                    zoom:
                        widget.crop.zoom +
                        (event.scrollDelta.dy > 0 ? -0.1 : 0.1),
                  ),
                );
              }
            }
          : null,
      child: GestureDetector(
        onDoubleTap: widget.editable
            ? () => widget.onChanged(ImageCropTransform.centered)
            : null,
        onScaleStart: enabled
            ? (details) {
                _startCrop = widget.crop;
                _startPoint = details.focalPoint;
              }
            : null,
        onScaleUpdate: enabled
            ? (details) {
                final delta = details.focalPoint - _startPoint;
                widget.onChanged(
                  _startCrop.copyWith(
                    zoom: _startCrop.zoom * details.scale,
                    focalX: _startCrop.focalX - 2 * delta.dx / widget.width,
                    focalY: _startCrop.focalY - 2 * delta.dy / widget.height,
                  ),
                );
              }
            : null,
        child: widget.child,
      ),
    );
  }
}
