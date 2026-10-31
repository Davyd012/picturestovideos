import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_fields.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';

class ImageSettingsScreen extends ConsumerWidget {
  ImageSettingsScreen({String? clipId, ImageSettingsRouteArgs? args, super.key})
    : args = args ?? ImageSettingsRouteArgs.forClip(clipId ?? '');
  final ImageSettingsRouteArgs args;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args.mediaId case final mediaId?) {
      final selection = ref.watch(editorMediaSelectionViewModelProvider);
      final media = selection.selectedMedia
          .where((item) => item.id == mediaId)
          .firstOrNull;
      if (media == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(context.l10n.noTimelineClips)),
        );
      }
      final clip = MediaTrackClipPayload(
        mediaId: media.id,
        title: media.title,
        tagline: media.tagline,
        start: Duration.zero,
        end: const Duration(seconds: 4),
        sourcePath: media.sourcePath,
        imageFit: selection.imageFitFor(media.id),
        cropTransform: selection.cropTransformFor(media.id),
      );
      final ratio =
          ref
              .watch(timelineViewModelProvider)
              .asData
              ?.value
              .selectedTemplate
              .aspectRatio ??
          VideoTemplateAspectRatio.landscape;
      return _SettingsForm(
        clip: clip,
        ratio: ratio,
        maxSeconds: 60,
        initialMotion: false,
        queuedMediaId: media.id,
      );
    }
    final timeline = ref.watch(timelineViewModelProvider).asData?.value;
    final project = timeline?.project;
    final clips = project == null
        ? <MediaTrackClipPayload>[]
        : ref
              .read(resolvePreviewClipsUseCaseProvider)
              .call(beatMap: project.beatMap, project: project);
    final index = clips.indexWhere((clip) => clip.clipId == args.clipId);
    if (index < 0 || project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.noTimelineClips)),
      );
    }
    final next = index + 1 < clips.length ? clips[index + 1] : null;
    final maxSeconds = next == null
        ? 60.0
        : math.max(
            0.1,
            (next.end - clips[index].start).inMilliseconds / 1000 - 0.1,
          );
    return _SettingsForm(
      clip: clips[index],
      ratio: project.template.aspectRatio,
      maxSeconds: maxSeconds,
      initialMotion:
          clips[index].motionFor(project.template).preset !=
          ClipMotionPreset.none,
      queuedMediaId: null,
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    required this.clip,
    required this.ratio,
    required this.maxSeconds,
    required this.initialMotion,
    required this.queuedMediaId,
  });
  final MediaTrackClipPayload clip;
  final VideoTemplateAspectRatio ratio;
  final double maxSeconds;
  final bool initialMotion;
  final String? queuedMediaId;
  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late VideoTemplateImageFit fit = widget.clip.imageFit;
  late ImageCropTransform crop = widget.clip.cropTransform;
  late VideoTemplateAspectRatio ratio = widget.ratio;
  late double duration =
      (widget.clip.end - widget.clip.start).inMilliseconds / 1000;
  late bool motion = widget.initialMotion;
  late final TextEditingController caption = TextEditingController(
    text: widget.clip.caption,
  );
  bool dirty = false;
  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(context.l10n.editorDiscardChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.remove),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) context.appNavigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final upper = math.max(0.1, math.max(widget.maxSeconds, duration));
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: close),
          title: Text(context.l10n.editClip),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: ratio.value,
                            child: ClipRect(
                              child: Transform.scale(
                                scale: fit == VideoTemplateImageFit.cover
                                    ? crop.zoom
                                    : 1,
                                alignment: Alignment(crop.focalX, crop.focalY),
                                child: MediaThumbnail(
                                  path: widget.clip.sourcePath,
                                  fit: fit == VideoTemplateImageFit.cover
                                      ? BoxFit.cover
                                      : BoxFit.contain,
                                  alignment: Alignment(
                                    crop.focalX,
                                    crop.focalY,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.queuedMediaId == null)
                              Text(context.l10n.editorOutputRatio),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(context.l10n.editorFit),
                                    selected:
                                        fit == VideoTemplateImageFit.contain,
                                    onSelected: (_) => setState(() {
                                      fit = VideoTemplateImageFit.contain;
                                      dirty = true;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text(context.l10n.editorFill),
                                    selected:
                                        fit == VideoTemplateImageFit.cover,
                                    onSelected: (_) => setState(() {
                                      fit = VideoTemplateImageFit.cover;
                                      dirty = true;
                                    }),
                                  ),
                                  if (widget.queuedMediaId == null)
                                    for (final value in [
                                      VideoTemplateAspectRatio.landscape,
                                      VideoTemplateAspectRatio.square,
                                      VideoTemplateAspectRatio.portrait,
                                    ]) ...[
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: Text(value.label),
                                        selected: ratio == value,
                                        onSelected: (_) => setState(() {
                                          ratio = value;
                                          dirty = true;
                                        }),
                                      ),
                                    ],
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _editCrop(context),
                              icon: const Icon(Icons.crop),
                              label: Text(context.l10n.adjustCrop),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.queuedMediaId == null) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.editorDisplayDuration,
                                    ),
                                  ),
                                  Text('${duration.toStringAsFixed(1)} s'),
                                ],
                              ),
                              Slider(
                                min: 0.1,
                                max: upper,
                                value: duration.clamp(0.1, upper),
                                onChanged: (value) => setState(() {
                                  duration = value;
                                  dirty = true;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: caption,
                            maxLength: 100,
                            decoration: InputDecoration(
                              labelText: context.l10n.editorOptionalCaption,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  caption.clear();
                                  setState(() => dirty = true);
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ),
                            onChanged: (_) => setState(() => dirty = true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: SwitchListTile(
                          secondary: const Icon(Icons.animation),
                          title: Text(context.l10n.editorSmoothAnimation),
                          value: motion,
                          onChanged: (value) => setState(() {
                            motion = value;
                            dirty = true;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(context.l10n.editorSave),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCrop(BuildContext context) async {
    var draftFit = fit;
    var draftCrop = crop;
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(context.l10n.adjustCrop),
          content: SingleChildScrollView(
            child: ClipFramingFields(
              imageFit: draftFit,
              crop: draftCrop,
              sourcePath: widget.clip.sourcePath,
              aspectRatio: ratio.value,
              onFitChanged: (value) => update(() => draftFit = value),
              onCropChanged: (value) => update(() => draftCrop = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.apply),
            ),
          ],
        ),
      ),
    );
    if (apply == true && mounted) {
      setState(() {
        fit = draftFit;
        crop = draftCrop;
        dirty = true;
      });
    }
  }

  void _save() {
    if (widget.queuedMediaId case final mediaId?) {
      final selection = ref.read(
        editorMediaSelectionViewModelProvider.notifier,
      );
      if (fit != widget.clip.imageFit) {
        selection.imageFitSelected(mediaId: mediaId, imageFit: fit);
      }
      if (crop != widget.clip.cropTransform) {
        selection.cropTransformChanged(mediaId: mediaId, transform: crop);
      }
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.appNavigator.maybePop();
      });
      return;
    }
    final timeline = ref.read(timelineViewModelProvider.notifier);
    if (ratio != widget.ratio) timeline.aspectRatioSelected(ratio);
    if (fit != widget.clip.imageFit) {
      timeline.clipImageFitChanged(clipId: widget.clip.clipId, imageFit: fit);
    }
    if (crop != widget.clip.cropTransform) {
      timeline.clipCropChanged(clipId: widget.clip.clipId, transform: crop);
    }
    final changedDuration = Duration(milliseconds: (duration * 1000).round());
    if (changedDuration != widget.clip.end - widget.clip.start) {
      timeline.clipTimingChanged(
        clipId: widget.clip.clipId,
        duration: changedDuration,
        snap: false,
      );
    }
    if (caption.text != widget.clip.caption) {
      timeline.captionChanged(
        clipId: widget.clip.clipId,
        caption: caption.text,
        supportingLine: widget.clip.captionSupportingLine,
      );
    }
    if (motion != widget.initialMotion) {
      timeline.clipMotionChanged(
        clipId: widget.clip.clipId,
        preset: motion ? ClipMotionPreset.slowZoomIn : ClipMotionPreset.none,
        intensity: null,
      );
    }
    setState(() => dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.appNavigator.maybePop();
    });
  }
}
