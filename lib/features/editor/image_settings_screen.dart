import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/clip_editor_controller.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_card.dart';
import 'package:picturestovideos/features/editor/widgets/caption_editor_preview.dart';
import 'package:picturestovideos/features/editor/widgets/caption_settings_fields.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_settings_card.dart';
import 'package:picturestovideos/features/editor/widgets/clip_motion_card.dart';
import 'package:picturestovideos/features/editor/widgets/clip_scope_selector.dart';
import 'package:picturestovideos/features/editor/widgets/transition_editor_fields.dart';
import 'package:picturestovideos/features/editor/widgets/transition_demo.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_preview.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

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
        template:
            ref
                .watch(timelineViewModelProvider)
                .asData
                ?.value
                .selectedTemplate ??
            VideoTemplates.cleanMemories,
        maxSeconds: 60,
        queuedMediaId: media.id,
        queuedMedia: media,
        initialSection: ImageSettingsSection.framing,
        next: null,
        index: selection.selectedMedia.indexWhere((item) => item.id == mediaId),
        count: selection.selectedMedia.length,
        snap: false,
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
      template: project.template,
      maxSeconds: maxSeconds,
      queuedMediaId: null,
      queuedMedia: null,
      initialSection:
          args.section == ImageSettingsSection.transition && next == null
          ? ImageSettingsSection.framing
          : args.section,
      next: next,
      index: index,
      count: clips.length,
      snap: project.snapToMarkers,
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    required this.clip,
    required this.ratio,
    required this.template,
    required this.maxSeconds,
    required this.queuedMediaId,
    required this.queuedMedia,
    required this.initialSection,
    required this.next,
    required this.index,
    required this.count,
    required this.snap,
  });
  final MediaTrackClipPayload clip;
  final VideoTemplateAspectRatio ratio;
  final VideoTemplate template;
  final double maxSeconds;
  final String? queuedMediaId;
  final LibraryMediaItem? queuedMedia;
  final ImageSettingsSection initialSection;
  final MediaTrackClipPayload? next;
  final int index;
  final int count;
  final bool snap;
  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final ClipEditorSeed seed = ClipEditorSeed(
    widget.clip,
    widget.ratio,
    widget.initialSection,
    snap: widget.snap,
  );
  ClipEditorDraft get draft => ref.read(clipEditorControllerProvider(seed));
  ClipEditorController get controller =>
      ref.read(clipEditorControllerProvider(seed).notifier);
  VideoTemplateImageFit get fit => draft.fit;
  set fit(VideoTemplateImageFit value) => controller.fitChanged(value);
  ImageCropTransform get crop => draft.crop;
  set crop(ImageCropTransform value) => controller.cropChanged(value);
  VideoTemplateAspectRatio get ratio => draft.ratio;
  set ratio(VideoTemplateAspectRatio value) => controller.ratioChanged(value);
  double get duration => draft.duration;
  set duration(double value) => controller.durationChanged(value);
  ImageSettingsSection get section => draft.section;
  set section(ImageSettingsSection value) => controller.sectionChanged(value);
  ClipMotionPreset? get motion => draft.motion;
  set motion(ClipMotionPreset? value) => controller.motionChanged(value);
  ClipMotionIntensity? get intensity => draft.intensity;
  set intensity(ClipMotionIntensity? value) =>
      controller.intensityChanged(value);
  bool get applyMotionToAll => draft.motionScope == ClipEditScope.all;
  set applyMotionToAll(bool value) => controller.motionScopeChanged(
    value ? ClipEditScope.all : ClipEditScope.clip,
  );
  bool get motionChanged => draft.motionChanged;
  set motionChanged(bool value) => controller.motionEdited(value);
  ClipTransitionType? get transition => draft.transition;
  set transition(ClipTransitionType? value) =>
      controller.transitionChanged(value);
  Duration get transitionDuration => draft.transitionDuration;
  set transitionDuration(Duration value) =>
      controller.transitionDurationChanged(value);
  int get transitionSelectionRevision => draft.transitionSelectionRevision;
  set transitionSelectionRevision(int value) =>
      controller.transitionPreviewRequested(value);
  CaptionSettings get captionSettings => draft.captionSettings;
  set captionSettings(CaptionSettings value) =>
      controller.captionSettingsChanged(value);
  CaptionEditorSection get captionSection => draft.captionSection;
  set captionSection(CaptionEditorSection value) =>
      controller.captionSectionChanged(value);
  double get previewFraction => draft.previewFraction;
  set previewFraction(double value) => controller.previewTimeChanged(value);
  bool get applyCaptionStyleToAll =>
      draft.captionStyleScope == ClipEditScope.all;
  set applyCaptionStyleToAll(bool value) => controller.captionStyleScopeChanged(
    value ? ClipEditScope.all : ClipEditScope.clip,
  );
  bool get applyCaptionToAll => switch (captionSection) {
    CaptionEditorSection.text => draft.captionTextScope == ClipEditScope.all,
    CaptionEditorSection.style => draft.captionStyleScope == ClipEditScope.all,
    CaptionEditorSection.position =>
      draft.captionPositionScope == ClipEditScope.all,
    CaptionEditorSection.timing =>
      draft.captionTimingScope == ClipEditScope.all,
  };
  bool get applyTransitionToAll => draft.transitionScope == ClipEditScope.all;
  late final TextEditingController caption = TextEditingController(
    text: widget.clip.caption,
  );
  late final TextEditingController supportingLine = TextEditingController(
    text: widget.clip.captionSupportingLine,
  );
  bool get dirty => draft.dirty;
  set dirty(bool value) => controller.dirtyChanged(value);
  bool get applyFramingToAll => draft.framingScope == ClipEditScope.all;
  set applyFramingToAll(bool value) => controller.framingScopeChanged(
    value ? ClipEditScope.all : ClipEditScope.clip,
  );
  @override
  void dispose() {
    caption.dispose();
    supportingLine.dispose();
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
      controller.dirtyChanged(false);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) context.appNavigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(clipEditorControllerProvider(seed));
    final capabilityState = widget.queuedMediaId == null
        ? ref.watch(renderCapabilitiesProvider)
        : null;
    final capabilities = capabilityState?.asData?.value;
    String? unavailable(bool supported, String unsupported) {
      if (capabilities == null) {
        return (capabilityState?.hasError ?? false)
            ? context.l10n.exportCapabilityProbeFailed
            : context.l10n.exportCapabilityChecking;
      }
      if (!capabilities.platformSupported) {
        return context.l10n.exportUnsupportedPlatform;
      }
      if (!capabilities.ffmpegAvailable) {
        return context.l10n.exportMissingFfmpeg;
      }
      return supported ? null : unsupported;
    }

    final motionUnavailable = unavailable(
      capabilities?.supportsMotion ?? false,
      context.l10n.editorMotionUnavailable,
    );
    final captionUnavailable = unavailable(
      capabilities?.supportsCaptions ?? false,
      context.l10n.editorCaptionUnavailable,
    );
    final transitionUnavailable = unavailable(
      capabilities?.supportsTransitions ?? false,
      context.l10n.editorTransitionUnavailable,
    );
    final resolvedTransition = widget.next == null
        ? null
        : ClipTransition.between(
            widget.clip.copyWith(
              transitionOverride: transition,
              clearTransitionOverride: transition == null,
              transitionDuration: transitionDuration,
            ),
            widget.next!,
            widget.template,
          );
    final upper = math.max(0.1, math.max(widget.maxSeconds, duration));
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = viewportHeight - keyboard - kToolbarHeight;
    final showPreview = keyboard == 0 || availableHeight >= 400;
    final previewHeight = keyboard == 0
        ? viewportHeight * 0.34
        : availableHeight * 0.25;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: close),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.editClip),
              Text(
                context.l10n.editorImageIndex(widget.index + 1, widget.count),
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (showPreview)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: previewHeight,
                    child:
                        section == ImageSettingsSection.text &&
                            widget.queuedMediaId == null
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final width = math.min(
                                constraints.maxWidth,
                                constraints.maxHeight * ratio.value,
                              );
                              final clipDuration = Duration(
                                milliseconds: (duration * 1000).round(),
                              );
                              return Center(
                                child: CaptionEditorPreview(
                                  sourcePath: widget.clip.sourcePath,
                                  title: caption.text,
                                  supportingLine: supportingLine.text,
                                  settings: captionSettings,
                                  template: widget.template.copyWith(
                                    aspectRatio: ratio,
                                  ),
                                  clipDuration: clipDuration,
                                  previewTime: Duration(
                                    microseconds:
                                        (clipDuration.inMicroseconds *
                                                previewFraction)
                                            .round(),
                                  ),
                                  width: width,
                                  crop: crop,
                                  imageFit: fit,
                                ),
                              );
                            },
                          )
                        : ClipFramingPreview(
                            sourcePath: widget.clip.sourcePath,
                            item: widget.queuedMedia,
                            fit: fit,
                            crop: crop,
                            aspectRatio: ratio.value,
                            editable: section == ImageSettingsSection.framing,
                            motion: section == ImageSettingsSection.motion
                                ? motion ??
                                      ClipMotionPreset.fromTemplate(
                                        widget.template.imageAnimation,
                                      )
                                : null,
                            onChanged: (value) => setState(() {
                              crop = value;
                              dirty = true;
                            }),
                          ),
                  ),
                ),
              if (widget.queuedMediaId == null &&
                  MediaQuery.viewInsetsOf(context).bottom == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<ImageSettingsSection>(
                      segments: [
                        ButtonSegment(
                          value: ImageSettingsSection.framing,
                          label: Text(context.l10n.editorCrop),
                        ),
                        ButtonSegment(
                          value: ImageSettingsSection.motion,
                          label: Text(context.l10n.motion),
                        ),
                        if (widget.next != null)
                          ButtonSegment(
                            value: ImageSettingsSection.transition,
                            label: Text(context.l10n.transitionToNext),
                          ),
                        ButtonSegment(
                          value: ImageSettingsSection.text,
                          label: Text(context.l10n.editorText),
                        ),
                        ButtonSegment(
                          value: ImageSettingsSection.timing,
                          label: Text(context.l10n.editorDisplayDuration),
                        ),
                      ],
                      selected: {section},
                      onSelectionChanged: (value) =>
                          setState(() => section = value.first),
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  child: ListView(
                    key: PageStorageKey(section),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (section == ImageSettingsSection.framing)
                        ClipFramingCard(
                          fit: fit,
                          crop: crop,
                          ratio: ratio,
                          sourcePath: widget.clip.sourcePath,
                          showRatio: widget.queuedMediaId == null,
                          all: applyFramingToAll,
                          onFitChanged: (value) => setState(() {
                            fit = value;
                            dirty = true;
                          }),
                          onCropChanged: (value) => setState(() {
                            crop = value;
                            dirty = true;
                          }),
                          onRatioChanged: (value) => setState(() {
                            ratio = value;
                            dirty = true;
                          }),
                          onScopeChanged: (value) => setState(() {
                            applyFramingToAll = value;
                            dirty = true;
                          }),
                        ),
                      if (widget.queuedMediaId == null &&
                          section == ImageSettingsSection.timing) ...[
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
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(context.l10n.snapToMarkers),
                                  subtitle: Text(context.l10n.snapDescription),
                                  value: draft.snap,
                                  onChanged: (value) =>
                                      controller.snapChanged(value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (widget.queuedMediaId == null &&
                          section == ImageSettingsSection.text) ...[
                        const SizedBox(height: 8),
                        ClipCaptionSettingsCard(
                          template: widget.template.copyWith(
                            aspectRatio: ratio,
                          ),
                          duration: duration,
                          caption: caption,
                          supportingLine: supportingLine,
                          settings: captionSettings,
                          section: captionSection,
                          previewFraction: previewFraction,
                          applyToAll: applyCaptionToAll,
                          enabled: captionUnavailable == null,
                          supportsBackdrop:
                              capabilities?.supportsCaptionBackdrop ?? false,
                          unavailableMessage: captionUnavailable,
                          onCaptionChanged: () => setState(
                            () => controller.captionChanged(
                              caption.text,
                              supportingLine.text,
                            ),
                          ),
                          onSettingsChanged: (value) => setState(() {
                            captionSettings = value;
                            dirty = true;
                          }),
                          onSectionChanged: (value) =>
                              setState(() => captionSection = value),
                          onPreviewFractionChanged: (value) => setState(() {
                            previewFraction = value;
                          }),
                          onScopeChanged: (value) => setState(() {
                            controller.captionScopeChanged(
                              captionSection,
                              value ? ClipEditScope.all : ClipEditScope.clip,
                            );
                            dirty = true;
                          }),
                        ),
                      ],
                      if (widget.queuedMediaId == null &&
                          section == ImageSettingsSection.transition &&
                          widget.next != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TransitionEditorFields(
                                  type: transition,
                                  inheritedType:
                                      ClipTransitionType.fromTemplate(
                                        widget.template.transition,
                                      ),
                                  duration: transitionDuration,
                                  enabled: transitionUnavailable == null,
                                  isClamped: resolvedTransition!.wasClamped,
                                  onTypeChanged: (value) => setState(() {
                                    transition = value;
                                    transitionSelectionRevision++;
                                    dirty = true;
                                  }),
                                  onDurationChanged: (value) => setState(() {
                                    transitionDuration = value;
                                    dirty = true;
                                  }),
                                ),
                                TransitionDemo(
                                  type:
                                      transition ??
                                      ClipTransitionType.fromTemplate(
                                        widget.template.transition,
                                      ),
                                  duration: resolvedTransition.duration,
                                  outgoingPath: widget.clip.sourcePath,
                                  incomingPath: widget.next!.sourcePath,
                                  selectionRevision:
                                      transitionSelectionRevision,
                                ),
                                if (transitionUnavailable != null)
                                  Text(
                                    transitionUnavailable,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ClipScopeSelector(
                                  all: applyTransitionToAll,
                                  enabled: transitionUnavailable == null,
                                  clipLabel:
                                      context.l10n.editorTransitionScopeOne,
                                  allLabel:
                                      context.l10n.editorTransitionScopeAll,
                                  onChanged: (value) {
                                    controller.transitionScopeChanged(
                                      value
                                          ? ClipEditScope.all
                                          : ClipEditScope.clip,
                                    );
                                    controller.dirtyChanged(true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.queuedMediaId == null &&
                          section == ImageSettingsSection.motion) ...[
                        ClipMotionCard(
                          template: widget.template,
                          motion: motion,
                          intensity: intensity,
                          all: applyMotionToAll,
                          enabled: motionUnavailable == null,
                          unavailableMessage: motionUnavailable,
                          onMotionChanged: (value) => setState(() {
                            motion = value;
                            motionChanged = true;
                            dirty = true;
                          }),
                          onIntensityChanged: (value) => setState(() {
                            intensity = value;
                            motionChanged = true;
                            dirty = true;
                          }),
                          onScopeChanged: (value) => setState(() {
                            applyMotionToAll = value;
                            motionChanged = true;
                            dirty = true;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: close,
                      child: Text(context.l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(context.l10n.editorSave),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (applyFramingToAll ||
        applyCaptionStyleToAll ||
        draft.captionTextScope == ClipEditScope.all ||
        draft.captionPositionScope == ClipEditScope.all ||
        draft.captionTimingScope == ClipEditScope.all ||
        applyTransitionToAll ||
        applyMotionToAll) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.editorBulkConfirm),
                const SizedBox(height: 8),
                if (applyFramingToAll)
                  Text(
                    '• ${context.l10n.editorCrop} — ${context.l10n.editorScopeAll}',
                  ),
                if (applyCaptionStyleToAll)
                  Text(
                    '• ${context.l10n.captionStyle} — ${context.l10n.editorScopeAll}',
                  ),
                if (draft.captionTextScope == ClipEditScope.all)
                  Text(
                    '• ${context.l10n.captionSectionText} — ${context.l10n.editorScopeAll}',
                  ),
                if (draft.captionPositionScope == ClipEditScope.all)
                  Text(
                    '• ${context.l10n.captionSectionPosition} — ${context.l10n.editorScopeAll}',
                  ),
                if (draft.captionTimingScope == ClipEditScope.all)
                  Text(
                    '• ${context.l10n.captionSectionTiming} — ${context.l10n.editorScopeAll}',
                  ),
                if (applyMotionToAll)
                  Text(
                    '• ${context.l10n.motion} — ${context.l10n.editorScopeAll}',
                  ),
                if (applyTransitionToAll)
                  Text(
                    '• ${context.l10n.transitionToNext} — ${context.l10n.editorTransitionScopeAll}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.apply),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final undo = controller.savePressed(
      queuedMediaId: widget.queuedMediaId,
      hasNext: widget.next != null,
    );
    if (undo != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.editorBulkSaved),
          action: SnackBarAction(label: context.l10n.undo, onPressed: undo),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.appNavigator.maybePop();
    });
  }
}
