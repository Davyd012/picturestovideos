import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/caption_editor_section.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

class ClipEditorSeed {
  const ClipEditorSeed(
    this.clip,
    this.ratio,
    this.section, {
    this.snap = false,
  });
  final MediaTrackClipPayload clip;
  final VideoTemplateAspectRatio ratio;
  final ImageSettingsSection section;
  final bool snap;
}

enum ClipEditScope { clip, all }

class ClipEditorDraft {
  const ClipEditorDraft({
    required this.fit,
    required this.crop,
    required this.ratio,
    required this.duration,
    required this.section,
    required this.motion,
    required this.intensity,
    required this.transition,
    required this.transitionDuration,
    required this.captionSettings,
    required this.caption,
    required this.supportingLine,
    this.framingScope = ClipEditScope.clip,
    this.motionScope = ClipEditScope.clip,
    this.transitionScope = ClipEditScope.clip,
    this.captionStyleScope = ClipEditScope.clip,
    this.captionTextScope = ClipEditScope.clip,
    this.captionPositionScope = ClipEditScope.clip,
    this.captionTimingScope = ClipEditScope.clip,
    this.motionChanged = false,
    this.dirty = false,
    this.captionSection = CaptionEditorSection.text,
    this.previewFraction = 0.5,
    this.transitionSelectionRevision = 0,
    this.snap = false,
  });

  factory ClipEditorDraft.fromSeed(ClipEditorSeed seed) => ClipEditorDraft(
    fit: seed.clip.imageFit,
    crop: seed.clip.cropTransform,
    ratio: seed.ratio,
    duration: (seed.clip.end - seed.clip.start).inMilliseconds / 1000,
    section: seed.section,
    motion: seed.clip.motionOverride,
    intensity: seed.clip.useStyleMotionIntensity
        ? null
        : seed.clip.motionIntensity,
    transition: seed.clip.transitionOverride,
    transitionDuration: seed.clip.transitionDuration,
    captionSettings: seed.clip.captionSettings,
    caption: seed.clip.caption,
    supportingLine: seed.clip.captionSupportingLine,
    snap: seed.snap,
  );

  final VideoTemplateImageFit fit;
  final ImageCropTransform crop;
  final VideoTemplateAspectRatio ratio;
  final double duration;
  final ImageSettingsSection section;
  final ClipMotionPreset? motion;
  final ClipMotionIntensity? intensity;
  final ClipTransitionType? transition;
  final Duration transitionDuration;
  final CaptionSettings captionSettings;
  final String caption;
  final String supportingLine;
  final ClipEditScope framingScope,
      motionScope,
      transitionScope,
      captionStyleScope;
  final ClipEditScope captionTextScope,
      captionPositionScope,
      captionTimingScope;
  final bool motionChanged, dirty;
  final bool snap;
  final CaptionEditorSection captionSection;
  final double previewFraction;
  final int transitionSelectionRevision;

  ClipEditorDraft copyWith({
    VideoTemplateImageFit? fit,
    ImageCropTransform? crop,
    VideoTemplateAspectRatio? ratio,
    double? duration,
    ImageSettingsSection? section,
    Object? motion = _unchanged,
    Object? intensity = _unchanged,
    Object? transition = _unchanged,
    Duration? transitionDuration,
    CaptionSettings? captionSettings,
    String? caption,
    String? supportingLine,
    ClipEditScope? framingScope,
    ClipEditScope? motionScope,
    ClipEditScope? transitionScope,
    ClipEditScope? captionStyleScope,
    ClipEditScope? captionTextScope,
    ClipEditScope? captionPositionScope,
    ClipEditScope? captionTimingScope,
    bool? motionChanged,
    bool? dirty,
    bool? snap,
    CaptionEditorSection? captionSection,
    double? previewFraction,
    int? transitionSelectionRevision,
  }) => ClipEditorDraft(
    fit: fit ?? this.fit,
    crop: crop ?? this.crop,
    ratio: ratio ?? this.ratio,
    duration: duration ?? this.duration,
    section: section ?? this.section,
    motion: identical(motion, _unchanged)
        ? this.motion
        : motion as ClipMotionPreset?,
    intensity: identical(intensity, _unchanged)
        ? this.intensity
        : intensity as ClipMotionIntensity?,
    transition: identical(transition, _unchanged)
        ? this.transition
        : transition as ClipTransitionType?,
    transitionDuration: transitionDuration ?? this.transitionDuration,
    captionSettings: captionSettings ?? this.captionSettings,
    caption: caption ?? this.caption,
    supportingLine: supportingLine ?? this.supportingLine,
    framingScope: framingScope ?? this.framingScope,
    motionScope: motionScope ?? this.motionScope,
    transitionScope: transitionScope ?? this.transitionScope,
    captionStyleScope: captionStyleScope ?? this.captionStyleScope,
    captionTextScope: captionTextScope ?? this.captionTextScope,
    captionPositionScope: captionPositionScope ?? this.captionPositionScope,
    captionTimingScope: captionTimingScope ?? this.captionTimingScope,
    motionChanged: motionChanged ?? this.motionChanged,
    dirty: dirty ?? this.dirty,
    snap: snap ?? this.snap,
    captionSection: captionSection ?? this.captionSection,
    previewFraction: previewFraction ?? this.previewFraction,
    transitionSelectionRevision:
        transitionSelectionRevision ?? this.transitionSelectionRevision,
  );
}

const _unchanged = Object();

final clipEditorControllerProvider = NotifierProvider.autoDispose
    .family<ClipEditorController, ClipEditorDraft, ClipEditorSeed>(
      ClipEditorController.new,
    );

class ClipEditorController extends Notifier<ClipEditorDraft> {
  ClipEditorController(this.seed);
  final ClipEditorSeed seed;
  @override
  ClipEditorDraft build() => ClipEditorDraft.fromSeed(seed);

  void fitChanged(VideoTemplateImageFit value) =>
      state = state.copyWith(fit: value);
  void cropChanged(ImageCropTransform value) =>
      state = state.copyWith(crop: value);
  void ratioChanged(VideoTemplateAspectRatio value) =>
      state = state.copyWith(ratio: value);
  void durationChanged(double value) => state = state.copyWith(duration: value);
  void snapChanged(bool value) => state = state.copyWith(snap: value);
  void sectionChanged(ImageSettingsSection value) =>
      state = state.copyWith(section: value);
  void motionChanged(ClipMotionPreset? value) =>
      state = state.copyWith(motion: value);
  void intensityChanged(ClipMotionIntensity? value) =>
      state = state.copyWith(intensity: value);
  void transitionChanged(ClipTransitionType? value) =>
      state = state.copyWith(transition: value);
  void transitionDurationChanged(Duration value) =>
      state = state.copyWith(transitionDuration: value);
  void captionSettingsChanged(CaptionSettings value) =>
      state = state.copyWith(captionSettings: value);
  void captionChanged(String title, String line) =>
      state = state.copyWith(caption: title, supportingLine: line, dirty: true);
  void framingScopeChanged(ClipEditScope value) =>
      state = state.copyWith(framingScope: value);
  void motionScopeChanged(ClipEditScope value) =>
      state = state.copyWith(motionScope: value);
  void transitionScopeChanged(ClipEditScope value) =>
      state = state.copyWith(transitionScope: value);
  void captionStyleScopeChanged(ClipEditScope value) =>
      state = state.copyWith(captionStyleScope: value);
  void captionScopeChanged(CaptionEditorSection section, ClipEditScope value) {
    state = switch (section) {
      CaptionEditorSection.text => state.copyWith(captionTextScope: value),
      CaptionEditorSection.style => state.copyWith(captionStyleScope: value),
      CaptionEditorSection.position => state.copyWith(
        captionPositionScope: value,
      ),
      CaptionEditorSection.timing => state.copyWith(captionTimingScope: value),
    };
  }

  void motionEdited(bool value) => state = state.copyWith(motionChanged: value);
  void dirtyChanged(bool value) => state = state.copyWith(dirty: value);
  void captionSectionChanged(CaptionEditorSection value) =>
      state = state.copyWith(captionSection: value);
  void previewTimeChanged(double value) =>
      state = state.copyWith(previewFraction: value);
  void transitionPreviewRequested(int value) =>
      state = state.copyWith(transitionSelectionRevision: value);

  /// Commits the draft and returns an undo action for a bulk edit, if any.
  void Function()? savePressed({String? queuedMediaId, required bool hasNext}) {
    final draft = state;
    final clip = seed.clip;
    final framingAll = draft.framingScope == ClipEditScope.all;
    final styleAll = draft.captionStyleScope == ClipEditScope.all;
    final textAll = draft.captionTextScope == ClipEditScope.all;
    final positionAll = draft.captionPositionScope == ClipEditScope.all;
    final timingAll = draft.captionTimingScope == ClipEditScope.all;
    final motionAll = draft.motionScope == ClipEditScope.all;
    final transitionAll = hasNext && draft.transitionScope == ClipEditScope.all;
    final timeline = ref.read(timelineViewModelProvider.notifier);
    if (queuedMediaId != null) {
      final selection = ref.read(
        editorMediaSelectionViewModelProvider.notifier,
      );
      if (framingAll) {
        final before = ref.read(editorMediaSelectionViewModelProvider);
        timeline.bulkEditStarted(framing: true);
        for (final item in before.selectedMedia) {
          selection.imageFitSelected(mediaId: item.id, imageFit: draft.fit);
          selection.cropTransformChanged(
            mediaId: item.id,
            transform: draft.crop,
          );
        }
        timeline.bulkEditFinished();
        final after = ref.read(editorMediaSelectionViewModelProvider);
        state = draft.copyWith(dirty: false);
        return () {
          if (timeline.bulkEditUndone()) {
            selection.queuedFramingRestored(expected: after, previous: before);
          }
        };
      }
      if (draft.fit != clip.imageFit) {
        selection.imageFitSelected(mediaId: queuedMediaId, imageFit: draft.fit);
      }
      if (draft.crop != clip.cropTransform) {
        selection.cropTransformChanged(
          mediaId: queuedMediaId,
          transform: draft.crop,
        );
      }
      state = draft.copyWith(dirty: false);
      return null;
    }

    final isBulk =
        framingAll ||
        styleAll ||
        textAll ||
        positionAll ||
        timingAll ||
        motionAll ||
        transitionAll;
    if (isBulk) {
      timeline.bulkEditStarted(
        framing: framingAll,
        captionStyle: styleAll,
        captionText: textAll,
        captionPosition: positionAll,
        captionTiming: timingAll,
        motion: motionAll,
        transition: transitionAll,
      );
    }
    if (draft.ratio != seed.ratio) timeline.aspectRatioSelected(draft.ratio);
    if (framingAll) {
      timeline.clipFramingAppliedToAll(imageFit: draft.fit, crop: draft.crop);
    }
    if (styleAll) timeline.captionStyleAppliedToAll(draft.captionSettings);
    if (textAll) {
      timeline.captionTextAppliedToAll(draft.caption, draft.supportingLine);
    }
    if (positionAll) {
      timeline.captionPositionAppliedToAll(draft.captionSettings);
    }
    if (timingAll) timeline.captionTimingAppliedToAll(draft.captionSettings);
    if (transitionAll) {
      timeline.clipTransitionAppliedToAll(
        type: draft.transition,
        duration: draft.transitionDuration,
      );
    }
    if (draft.fit != clip.imageFit) {
      timeline.clipImageFitChanged(clipId: clip.clipId, imageFit: draft.fit);
    }
    if (draft.crop != clip.cropTransform) {
      timeline.clipCropChanged(clipId: clip.clipId, transform: draft.crop);
    }
    final duration = Duration(milliseconds: (draft.duration * 1000).round());
    if (duration != clip.end - clip.start) {
      timeline.clipTimingChanged(
        clipId: clip.clipId,
        duration: duration,
        snap: draft.snap,
      );
    }
    if (draft.caption != clip.caption ||
        draft.supportingLine != clip.captionSupportingLine) {
      timeline.captionChanged(
        clipId: clip.clipId,
        caption: draft.caption,
        supportingLine: draft.supportingLine,
      );
    }
    if (draft.captionSettings != clip.captionSettings) {
      timeline.captionSettingsChanged(
        clipId: clip.clipId,
        settings: draft.captionSettings,
      );
    }
    if (draft.motionChanged) {
      if (motionAll) {
        timeline.clipMotionAppliedToAll(
          preset: draft.motion,
          intensity: draft.intensity,
        );
      } else {
        timeline.clipMotionChanged(
          clipId: clip.clipId,
          preset: draft.motion,
          intensity: draft.intensity,
        );
      }
    }
    if (hasNext &&
        (draft.transition != clip.transitionOverride ||
            draft.transitionDuration != clip.transitionDuration)) {
      timeline.clipTransitionChanged(
        clipId: clip.clipId,
        type: draft.transition,
        duration: draft.transitionDuration,
      );
    }
    if (isBulk) timeline.bulkEditFinished();
    state = draft.copyWith(dirty: false);
    return isBulk
        ? () {
            timeline.bulkEditUndone();
          }
        : null;
  }
}
