import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_fields.dart';
import 'package:picturestovideos/features/editor/widgets/caption_settings_fields.dart';
import 'package:picturestovideos/features/editor/widgets/caption_editor_preview.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_list.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/features/editor/widgets/transition_editor_fields.dart';
import 'package:picturestovideos/features/editor/widgets/clip_timing_fields.dart';
import 'package:picturestovideos/core/timeline/application/edit_clip_boundary_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ClipCaptionsEditor extends StatelessWidget {
  const ClipCaptionsEditor({
    required this.clips,
    required this.onCaptionChanged,
    this.onMotionChanged,
    this.onTransitionChanged,
    this.template,
    this.snapToMarkers = true,
    this.onTimingChanged,
    this.onCaptionSettingsChanged,
    this.onApplyStyleToAll,
    this.onSelectClip,
    this.onRemoveClip,
    this.onMoveClip,
    this.onReorderClip,
    this.onFramingChanged,
    this.renderCapabilities,
    this.gateRenderCapabilities = false,
    this.capabilityProbeFailed = false,
    super.key,
  });

  final List<MediaTrackClipPayload> clips;
  final void Function(String clipId, String title, String supportingLine)
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
  final ValueChanged<CaptionSettings>? onApplyStyleToAll;
  final ValueChanged<MediaTrackClipPayload>? onSelectClip;
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
    return ClipCaptionList(
      clips: clips,
      onEdit: (clip, next) => _edit(context, clip, next),
      onSelect: onSelectClip,
      onRemove: onRemoveClip,
      onMove: onMoveClip,
      onReorder: onReorderClip,
    );
  }

  Future<void> _edit(
    BuildContext context,
    MediaTrackClipPayload clip,
    MediaTrackClipPayload? next,
  ) async {
    var title = clip.caption;
    var supportingLine = clip.captionSupportingLine;
    var captionSettings = clip.captionSettings;
    var imageFit = clip.imageFit;
    var crop = clip.cropTransform;
    var motion = clip.motionOverride;
    var intensity = clip.useStyleMotionIntensity ? null : clip.motionIntensity;
    var transition = clip.transitionOverride;
    var transitionDuration = clip.transitionDuration;
    final initialDuration = clip.end - clip.start;
    var durationInput = (initialDuration.inMilliseconds / 1000).toStringAsFixed(
      3,
    );
    var snap = snapToMarkers;
    var previewFraction = 0.5;
    var captionSection = CaptionEditorSection.text;
    final previewWidth = math.max(
      0.0,
      math.min(MediaQuery.sizeOf(context).width - 48, 560.0),
    );
    final captionUnavailable = _featureUnavailableReason(
      context,
      supported:
          !gateRenderCapabilities ||
          (renderCapabilities?.supportsCaptions ?? false),
      unsupportedMessage: context.l10n.editorCaptionUnavailable,
    );
    final motionUnavailable = _featureUnavailableReason(
      context,
      supported:
          !gateRenderCapabilities ||
          (renderCapabilities?.supportsMotion ?? false),
      unsupportedMessage: context.l10n.editorMotionUnavailable,
    );
    final transitionUnavailable = _featureUnavailableReason(
      context,
      supported:
          !gateRenderCapabilities ||
          (renderCapabilities?.supportsTransitions ?? false),
      unsupportedMessage: context.l10n.editorTransitionUnavailable,
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.editClip),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onFramingChanged != null)
                    ClipFramingFields(
                      imageFit: imageFit,
                      crop: crop,
                      sourcePath: clip.sourcePath,
                      aspectRatio: (template ?? VideoTemplates.cleanMemories)
                          .aspectRatio
                          .value,
                      onFitChanged: (value) =>
                          setDialogState(() => imageFit = value),
                      onCropChanged: (value) =>
                          setDialogState(() => crop = value),
                    ),
                  if (onTimingChanged != null)
                    ClipTimingFields(
                      initialDuration: initialDuration,
                      maxDuration: next == null
                          ? EditClipBoundaryUseCase.maximumEnd - clip.start
                          : next.end -
                                clip.start -
                                EditClipBoundaryUseCase.minimumClipDuration,
                      snap: snap,
                      onDurationChanged: (value) =>
                          setDialogState(() => durationInput = value),
                      onSnapChanged: (value) =>
                          setDialogState(() => snap = value),
                    ),
                  if (captionSection == CaptionEditorSection.text)
                    TextFormField(
                      initialValue: title,
                      maxLines: 2,
                      enabled: captionUnavailable == null,
                      decoration: InputDecoration(
                        labelText: context.l10n.captionTitle,
                      ),
                      onChanged: (value) => setDialogState(() => title = value),
                    ),
                  if (captionSection == CaptionEditorSection.text)
                    TextFormField(
                      initialValue: supportingLine,
                      maxLines: 2,
                      enabled: captionUnavailable == null,
                      decoration: InputDecoration(
                        labelText: context.l10n.captionSupportingLine,
                      ),
                      onChanged: (value) =>
                          setDialogState(() => supportingLine = value),
                    ),
                  if (template != null && onCaptionSettingsChanged != null) ...[
                    const SizedBox(height: 16),
                    CaptionEditorPreview(
                      sourcePath: clip.sourcePath,
                      title: title,
                      supportingLine: supportingLine,
                      settings: captionSettings,
                      template: template!,
                      clipDuration: initialDuration,
                      previewTime: Duration(
                        microseconds:
                            (initialDuration.inMicroseconds * previewFraction)
                                .round(),
                      ),
                      width: previewWidth,
                    ),
                    Text(
                      context.l10n.captionTiming,
                      style: context.textTheme.labelLarge,
                    ),
                    Slider(
                      min: 0,
                      max: 1,
                      divisions: 100,
                      value: previewFraction,
                      semanticFormatterCallback: (value) =>
                          '${(initialDuration.inSeconds * value).toStringAsFixed(1)} s',
                      onChanged: (value) =>
                          setDialogState(() => previewFraction = value),
                    ),
                  ],
                  if (onCaptionSettingsChanged != null && template != null)
                    Builder(
                      builder: (context) {
                        final ratio = template!.aspectRatio;
                        final layout = CaptionLayout(
                          title: title,
                          supportingLine: supportingLine,
                          template: template!,
                          settings: captionSettings,
                          width: ratio.exportWidth,
                          height: ratio.exportHeight,
                        );
                        final seconds = double.tryParse(
                          durationInput.replaceAll(',', '.'),
                        );
                        final clipDuration =
                            seconds != null && seconds.isFinite && seconds > 0
                            ? Duration(milliseconds: (seconds * 1000).round())
                            : initialDuration;
                        final visible = Duration(
                          microseconds:
                              (clipDuration.inMicroseconds *
                                      (captionSettings.endFraction -
                                          captionSettings.startFraction))
                                  .round(),
                        );
                        return CaptionSettingsFields(
                          settings: captionSettings,
                          section: captionSection,
                          onSectionChanged: (section) =>
                              setDialogState(() => captionSection = section),
                          overflow: layout.overflow,
                          shortReadingTime: layout.readingTimeIsShort(visible),
                          clipDuration: clipDuration,
                          supportsBackdrop:
                              !gateRenderCapabilities ||
                              (renderCapabilities?.supportsCaptionBackdrop ??
                                  false),
                          enabled: captionUnavailable == null,
                          onChanged: (value) =>
                              setDialogState(() => captionSettings = value),
                        );
                      },
                    ),
                  if (captionUnavailable != null)
                    _CapabilityNotice(message: captionUnavailable),
                  if (onMotionChanged != null) ...[
                    DropdownButtonFormField<ClipMotionPreset?>(
                      initialValue: motion,
                      decoration: InputDecoration(
                        labelText: context.l10n.motion,
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.l10n.styleDefault),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionPreset.none,
                          child: Text(context.l10n.motionNone),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionPreset.slowZoomIn,
                          child: Text(context.l10n.motionZoomIn),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionPreset.slowZoomOut,
                          child: Text(context.l10n.motionZoomOut),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionPreset.gentlePan,
                          child: Text(context.l10n.motionPan),
                        ),
                      ],
                      onChanged: motionUnavailable == null
                          ? (value) => setDialogState(() => motion = value)
                          : null,
                    ),
                    DropdownButtonFormField<ClipMotionIntensity?>(
                      initialValue: intensity,
                      decoration: InputDecoration(
                        labelText: context.l10n.motionIntensity,
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.l10n.styleDefault),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionIntensity.subtle,
                          child: Text(context.l10n.motionSubtle),
                        ),
                        DropdownMenuItem(
                          value: ClipMotionIntensity.moreMovement,
                          child: Text(context.l10n.motionMore),
                        ),
                      ],
                      onChanged: motionUnavailable == null
                          ? (value) => setDialogState(() => intensity = value)
                          : null,
                    ),
                    if (motionUnavailable != null)
                      _CapabilityNotice(message: motionUnavailable),
                  ],
                  if (onTransitionChanged != null &&
                      next != null &&
                      template != null)
                    TransitionEditorFields(
                      type: transition,
                      duration: transitionDuration,
                      enabled: transitionUnavailable == null,
                      isClamped: ClipTransition.between(
                        clip.copyWith(
                          transitionOverride: transition,
                          clearTransitionOverride: transition == null,
                          transitionDuration: transitionDuration,
                        ),
                        next,
                        template!,
                      ).wasClamped,
                      onTypeChanged: (value) =>
                          setDialogState(() => transition = value),
                      onDurationChanged: (value) =>
                          setDialogState(() => transitionDuration = value),
                    ),
                  if (transitionUnavailable != null &&
                      onTransitionChanged != null &&
                      next != null)
                    _CapabilityNotice(message: transitionUnavailable),
                ],
              ),
            ),
          ),
          actions: [
            if (clips.length > 1 && onApplyStyleToAll != null)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      content: Text(context.l10n.captionApplyAllStylesConfirm),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(context.l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(context.l10n.apply),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) onApplyStyleToAll!(captionSettings);
                },
                child: Text(context.l10n.captionApplyAllStyles),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(context.l10n.apply),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      onFramingChanged?.call(clip.clipId, imageFit, crop);
      onCaptionChanged(clip.clipId, title, supportingLine);
      onCaptionSettingsChanged?.call(clip.clipId, captionSettings);
      onMotionChanged?.call(clip.clipId, motion, intensity);
      if (next != null) {
        onTransitionChanged?.call(clip.clipId, transition, transitionDuration);
      }
      if (onTimingChanged != null) {
        final seconds = double.parse(durationInput.replaceAll(',', '.'));
        final edited = Duration(milliseconds: (seconds * 1000).round());
        onTimingChanged!(
          clip.clipId,
          edited.inMilliseconds == initialDuration.inMilliseconds
              ? null
              : edited,
          snap,
        );
      }
    }
  }

  String? _featureUnavailableReason(
    BuildContext context, {
    required bool supported,
    required String unsupportedMessage,
  }) {
    if (!gateRenderCapabilities || supported) return null;
    final capabilities = renderCapabilities;
    if (capabilities == null) {
      return capabilityProbeFailed
          ? context.l10n.exportCapabilityProbeFailed
          : context.l10n.exportCapabilityChecking;
    }
    if (!capabilities.platformSupported) {
      return context.l10n.exportUnsupportedPlatform;
    }
    if (!capabilities.ffmpegAvailable) {
      return context.l10n.exportMissingFfmpeg;
    }
    return unsupportedMessage;
  }
}

class _CapabilityNotice extends StatelessWidget {
  const _CapabilityNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(message, style: context.textTheme.bodySmall),
    ),
  );
}
