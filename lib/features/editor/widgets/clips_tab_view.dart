import 'dart:io';

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/clip_captions_editor.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class ClipsTabView extends StatelessWidget {
  const ClipsTabView({
    required this.selectedMedia,
    required this.selectedImageFits,
    required this.selectedCropTransforms,
    required this.onReorderMedia,
    required this.onImageFitSelected,
    required this.onCropTransformChanged,
    required this.onApplyImageFitToAll,
    required this.onMoveMediaToPosition,
    required this.onOpenTimeline,
    this.timelineClips = const [],
    this.onCaptionChanged,
    this.onMotionChanged,
    this.onTransitionChanged,
    this.template,
    this.snapToMarkers = true,
    this.onTimingChanged,
    this.onCaptionSettingsChanged,
    this.onApplyCaptionStyleToAll,
    this.onSelectTimelineClip,
    this.onRemoveClip,
    this.onMoveClip,
    this.onReorderClip,
    this.onFramingChanged,
    this.renderCapabilities,
    this.gateRenderCapabilities = false,
    this.capabilityProbeFailed = false,
    super.key,
  });

  final List<LibraryMediaItem> selectedMedia;
  final Map<String, VideoTemplateImageFit> selectedImageFits;
  final Map<String, ImageCropTransform> selectedCropTransforms;
  final void Function(int oldIndex, int newIndex) onReorderMedia;
  final void Function(String mediaId, VideoTemplateImageFit imageFit)
  onImageFitSelected;
  final void Function(String mediaId, ImageCropTransform transform)
  onCropTransformChanged;
  final ValueChanged<VideoTemplateImageFit> onApplyImageFitToAll;
  final void Function(String mediaId, int position) onMoveMediaToPosition;
  final VoidCallback onOpenTimeline;
  final List<MediaTrackClipPayload> timelineClips;
  final void Function(String clipId, String title, String supportingLine)?
  onCaptionChanged;
  final void Function(
    String clipId,
    ClipMotionPreset? preset,
    ClipMotionIntensity? intensity,
  )?
  onMotionChanged;
  final void Function(
    String clipId,
    ClipTransitionType? type,
    Duration duration,
  )?
  onTransitionChanged;
  final VideoTemplate? template;
  final bool snapToMarkers;
  final void Function(String clipId, Duration? duration, bool snap)?
  onTimingChanged;
  final void Function(String clipId, CaptionSettings settings)?
  onCaptionSettingsChanged;
  final ValueChanged<CaptionSettings>? onApplyCaptionStyleToAll;
  final ValueChanged<MediaTrackClipPayload>? onSelectTimelineClip;
  final ValueChanged<String>? onRemoveClip;
  final bool Function(String clipId, int position)? onMoveClip;
  final bool Function(String clipId, int position)? onReorderClip;
  final void Function(
    String clipId,
    VideoTemplateImageFit fit,
    ImageCropTransform crop,
  )?
  onFramingChanged;
  final RenderCapabilities? renderCapabilities;
  final bool gateRenderCapabilities;
  final bool capabilityProbeFailed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onCaptionChanged != null)
          Expanded(
            child: ClipCaptionsEditor(
              clips: timelineClips,
              onCaptionChanged: onCaptionChanged!,
              onMotionChanged: onMotionChanged,
              onTransitionChanged: onTransitionChanged,
              template: template,
              snapToMarkers: snapToMarkers,
              onTimingChanged: onTimingChanged,
              onCaptionSettingsChanged: onCaptionSettingsChanged,
              onApplyStyleToAll: onApplyCaptionStyleToAll,
              onSelectClip: onSelectTimelineClip,
              onRemoveClip: onRemoveClip,
              onMoveClip: onMoveClip,
              onReorderClip: onReorderClip,
              onFramingChanged: onFramingChanged,
              renderCapabilities: renderCapabilities,
              gateRenderCapabilities: gateRenderCapabilities,
              capabilityProbeFailed: capabilityProbeFailed,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.queuedImages(selectedMedia.length)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => _QueueWorkspace(
                    items: selectedMedia,
                    imageFits: selectedImageFits,
                    cropTransforms: selectedCropTransforms,
                    onImageFitSelected: onImageFitSelected,
                    onCropTransformChanged: onCropTransformChanged,
                    onApplyImageFitToAll: onApplyImageFitToAll,
                    onMoveMediaToPosition: onMoveMediaToPosition,
                  ),
                ),
              );
            }
            return ExpansionTile(
              title: Text(context.l10n.queuedImages(selectedMedia.length)),
              subtitle: Text(context.l10n.queuedImagesPurpose),
              children: [
                ExpansionTile(
                  title: Text(context.l10n.bulkImageTools),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: selectedMedia.isEmpty
                              ? null
                              : () => onApplyImageFitToAll(
                                  VideoTemplateImageFit.cover,
                                ),
                          icon: const Icon(Icons.crop),
                          label: Text(context.l10n.cropAll),
                        ),
                        TextButton.icon(
                          onPressed: selectedMedia.isEmpty
                              ? null
                              : () => onApplyImageFitToAll(
                                  VideoTemplateImageFit.contain,
                                ),
                          icon: const Icon(Icons.fit_screen),
                          label: Text(context.l10n.fullImageForAll),
                        ),
                      ],
                    ),
                  ],
                ),
                if (selectedMedia.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: selectedMedia.length,
                    onReorderItem: onReorderMedia,
                    itemBuilder: (context, index) {
                      final item = selectedMedia[index];
                      return Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ClipListItem(
                          item: item,
                          index: index,
                          canReorder: selectedMedia.length > 1,
                          imageFit: _imageFitFor(item.id),
                          onImageFitSelected: (imageFit) =>
                              onImageFitSelected(item.id, imageFit),
                          cropTransform:
                              selectedCropTransforms[item.id] ??
                              ImageCropTransform.centered,
                          onCropTransformChanged: (transform) =>
                              onCropTransformChanged(item.id, transform),
                          itemCount: selectedMedia.length,
                          onMoveToPosition: (position) =>
                              onMoveMediaToPosition(item.id, position),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: selectedMedia.isEmpty ? null : onOpenTimeline,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(context.l10n.reviewSequence),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onOpenTimeline,
              icon: const Icon(Icons.timeline),
              label: Text(context.l10n.openTimeline),
            ),
          ],
        ),
      ],
    );
  }

  VideoTemplateImageFit _imageFitFor(String mediaId) {
    return selectedImageFits[mediaId] ?? VideoTemplateImageFit.cover;
  }
}

class _QueueWorkspace extends ConsumerWidget {
  const _QueueWorkspace({
    required this.items,
    required this.imageFits,
    required this.cropTransforms,
    required this.onImageFitSelected,
    required this.onCropTransformChanged,
    required this.onApplyImageFitToAll,
    required this.onMoveMediaToPosition,
  });

  final List<LibraryMediaItem> items;
  final Map<String, VideoTemplateImageFit> imageFits;
  final Map<String, ImageCropTransform> cropTransforms;
  final void Function(String, VideoTemplateImageFit) onImageFitSelected;
  final void Function(String, ImageCropTransform) onCropTransformChanged;
  final ValueChanged<VideoTemplateImageFit> onApplyImageFitToAll;
  final void Function(String, int) onMoveMediaToPosition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(editorMediaSelectionViewModelProvider);
    final media = queue.selectedMedia;
    return FractionallySizedBox(
      heightFactor: 1,
      child: Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: () => Navigator.pop(context)),
          title: Text(context.l10n.queuedImages(media.length)),
          actions: [
            PopupMenuButton<VideoTemplateImageFit>(
              tooltip: context.l10n.bulkImageTools,
              onSelected: onApplyImageFitToAll,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: VideoTemplateImageFit.cover,
                  child: Text(context.l10n.cropAll),
                ),
                PopupMenuItem(
                  value: VideoTemplateImageFit.contain,
                  child: Text(context.l10n.fullImageForAll),
                ),
              ],
            ),
          ],
        ),
        body: media.isEmpty
            ? Center(child: Text(context.l10n.queuedImages(0)))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final item = media[index];
                  return InkWell(
                    key: ValueKey(item.id),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _QueueThumbnail(
                                item: item,
                                fit: BoxFit.contain,
                              ),
                            ),
                            _ClipListItem(
                              item: item,
                              index: index,
                              canReorder: false,
                              itemCount: media.length,
                              imageFit: queue.imageFitFor(item.id),
                              cropTransform: queue.cropTransformFor(item.id),
                              onImageFitSelected: (fit) =>
                                  onImageFitSelected(item.id, fit),
                              onCropTransformChanged: (crop) =>
                                  onCropTransformChanged(item.id, crop),
                              onMoveToPosition: (position) =>
                                  onMoveMediaToPosition(item.id, position),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _QueueThumbnail(item: item),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: context.colors.surface,
                              foregroundColor: context.colors.onSurface,
                              child: Text('${index + 1}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _QueueThumbnail extends StatelessWidget {
  const _QueueThumbnail({required this.item, this.fit = BoxFit.cover});
  final LibraryMediaItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        ColoredBox(
          color: context.colors.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        );
    if (item.thumbnailBytes.isNotEmpty) {
      return Image.memory(
        item.thumbnailBytes,
        fit: fit,
        cacheWidth: 400,
        errorBuilder: fallback,
      );
    }
    if (item.sourcePath.isNotEmpty) {
      return Image.file(
        File(item.sourcePath),
        fit: fit,
        cacheWidth: 400,
        errorBuilder: fallback,
      );
    }
    return fallback(context, StateError('Missing image'), null);
  }
}

class _ClipListItem extends StatelessWidget {
  const _ClipListItem({
    required this.item,
    required this.index,
    required this.canReorder,
    this.imageFit = VideoTemplateImageFit.cover,
    this.onImageFitSelected,
    this.cropTransform = ImageCropTransform.centered,
    this.onCropTransformChanged,
    this.itemCount = 0,
    this.onMoveToPosition,
  });

  final LibraryMediaItem item;
  final int index;
  final bool canReorder;
  final VideoTemplateImageFit imageFit;
  final ValueChanged<VideoTemplateImageFit>? onImageFitSelected;
  final ImageCropTransform cropTransform;
  final ValueChanged<ImageCropTransform>? onCropTransformChanged;
  final int itemCount;
  final ValueChanged<int>? onMoveToPosition;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Thumbnail(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (onMoveToPosition != null)
                  IconButton(
                    onPressed: () => _openMoveDialog(context),
                    tooltip: context.l10n.moveToPosition,
                    icon: const Icon(Icons.format_list_numbered),
                  ),
                if (canReorder)
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ImageFitSelector(
              imageFit: imageFit,
              onImageFitSelected: onImageFitSelected,
            ),
            if (imageFit == VideoTemplateImageFit.cover) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onCropTransformChanged == null
                      ? null
                      : () => _openCropEditor(context),
                  icon: const Icon(Icons.open_with),
                  label: Text(context.l10n.adjustCrop),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openMoveDialog(BuildContext context) async {
    var input = '${index + 1}';
    final position = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.moveImage),
        content: TextFormField(
          initialValue: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (value) => input = value,
          decoration: InputDecoration(
            labelText: context.l10n.position,
            helperText: context.l10n.positionRange(itemCount),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(input);
              if (value == null || value < 1 || value > itemCount) {
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: Text(context.l10n.move),
          ),
        ],
      ),
    );
    if (position != null) {
      onMoveToPosition?.call(position);
    }
  }

  Future<void> _openCropEditor(BuildContext context) async {
    final transform = await showDialog<ImageCropTransform>(
      context: context,
      builder: (context) =>
          _CropEditorDialog(item: item, initialTransform: cropTransform),
    );
    if (transform != null) {
      onCropTransformChanged?.call(transform);
    }
  }
}

class _ImageFitSelector extends StatelessWidget {
  const _ImageFitSelector({
    required this.imageFit,
    required this.onImageFitSelected,
  });

  final VideoTemplateImageFit imageFit;
  final ValueChanged<VideoTemplateImageFit>? onImageFitSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<VideoTemplateImageFit>(
      initialValue: imageFit,
      isExpanded: true,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.aspect_ratio)),
      items: [
        DropdownMenuItem(
          value: VideoTemplateImageFit.cover,
          child: Text(
            context.l10n.fillFrameCrop,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: VideoTemplateImageFit.contain,
          child: Text(
            context.l10n.fullImage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: onImageFitSelected == null
          ? null
          : (value) {
              if (value != null) {
                onImageFitSelected!(value);
              }
            },
    );
  }
}

class _CropEditorDialog extends StatefulWidget {
  const _CropEditorDialog({required this.item, required this.initialTransform});

  final LibraryMediaItem item;
  final ImageCropTransform initialTransform;

  @override
  State<_CropEditorDialog> createState() => _CropEditorDialogState();
}

class _CropEditorDialogState extends State<_CropEditorDialog> {
  late ImageCropTransform _transform;
  late ImageCropTransform _gestureStartTransform;
  Offset _gestureStartPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transform = widget.initialTransform;
    _gestureStartTransform = _transform;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.adjustCrop),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          final change = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
                          setState(() {
                            _transform = _transform.copyWith(
                              zoom: _transform.zoom + change,
                            );
                          });
                        }
                      },
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _gestureStartTransform = _transform;
                          _gestureStartPoint = details.focalPoint;
                        },
                        onScaleUpdate: (details) {
                          final delta = details.focalPoint - _gestureStartPoint;
                          setState(() {
                            _transform = _gestureStartTransform.copyWith(
                              zoom: _gestureStartTransform.zoom * details.scale,
                              focalX:
                                  _gestureStartTransform.focalX -
                                  delta.dx / (constraints.maxWidth / 2),
                              focalY:
                                  _gestureStartTransform.focalY -
                                  delta.dy / (constraints.maxHeight / 2),
                            );
                          });
                        },
                        child: _CropPreview(
                          item: widget.item,
                          transform: _transform,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.zoom_in),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: ImageCropTransform.maxZoom,
                    value: _transform.zoom,
                    onChanged: (zoom) {
                      setState(() {
                        _transform = _transform.copyWith(zoom: zoom);
                      });
                    },
                  ),
                ),
                Text('${_transform.zoom.toStringAsFixed(1)}×'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _transform = ImageCropTransform.centered;
            });
          },
          child: Text(context.l10n.reset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_transform),
          child: Text(context.l10n.apply),
        ),
      ],
    );
  }
}

class _CropPreview extends StatelessWidget {
  const _CropPreview({required this.item, required this.transform});

  final LibraryMediaItem item;
  final ImageCropTransform transform;

  @override
  Widget build(BuildContext context) {
    final image = item.thumbnailBytes.isNotEmpty
        ? Image.memory(
            item.thumbnailBytes,
            fit: BoxFit.cover,
            alignment: Alignment(transform.focalX, transform.focalY),
          )
        : Image.file(
            File(item.sourcePath),
            fit: BoxFit.cover,
            alignment: Alignment(transform.focalX, transform.focalY),
          );
    return ColoredBox(
      color: context.colors.scrim,
      child: Transform.scale(
        scale: transform.zoom,
        alignment: Alignment(transform.focalX, transform.focalY),
        child: image,
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final LibraryMediaItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(dimension: 56, child: _thumbnail(context)),
    );
  }

  Widget _thumbnail(BuildContext context) {
    if (item.thumbnailBytes.isNotEmpty) {
      return Image.memory(item.thumbnailBytes, fit: BoxFit.cover);
    }
    if (item.sourcePath.isNotEmpty) {
      return Image.file(
        File(item.sourcePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: context.colors.primaryContainer,
      child: Icon(
        Icons.image_outlined,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }
}
