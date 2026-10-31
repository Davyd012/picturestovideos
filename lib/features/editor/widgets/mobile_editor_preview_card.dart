import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/preview/domain/caption_render_colors.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';
import 'package:picturestovideos/features/editor/editor_preview_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class MobileEditorPreviewCard extends ConsumerWidget {
  const MobileEditorPreviewCard({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.previewState,
    this.audioSourcePath,
    this.compact = false,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final EditorPreviewState previewState;
  final String? audioSourcePath;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewFrame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(
          beatMap: beatMap,
          project: project,
          currentTime: playback?.currentTime ?? Duration.zero,
        );
    final duration =
        project?.videoDuration ??
        playback?.sourceDuration ??
        previewState.result?.totalDuration ??
        _fallbackDuration;
    final currentTime = playback?.currentTime ?? Duration.zero;
    final progress = _progress(currentTime, duration, previewFrame.progress);
    final aspectRatio = project?.template.aspectRatio.value ?? 16 / 9;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: CompositionPreviewCanvas(
              frame: previewFrame,
              template: project?.template,
            ),
          ),
          ListTile(
            title: Text(context.l10n.editingPreview),
            trailing: Text(
              '${_formatDuration(currentTime)} / ${_formatDuration(duration)}',
            ),
          ),
          LinearProgressIndicator(value: progress, minHeight: 6),
          if (!compact && (previewState.hasRenderedResult || project != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    isThreeLine: true,
                    title: Text(context.l10n.renderedPreview),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (previewState.hasRenderedResult)
                          Text(
                            previewState.isRenderedPreviewStale
                                ? context.l10n.renderedPreviewStale
                                : context.l10n.renderedPreviewCurrent,
                          ),
                        Text(context.l10n.renderedPreviewSource),
                      ],
                    ),
                  ),
                  if (!previewState.isReady ||
                      previewState.isRenderedPreviewStale)
                    FilledButton.icon(
                      onPressed: project == null || previewState.isRendering
                          ? null
                          : () => ref
                                .read(editorPreviewViewModelProvider.notifier)
                                .renderPreview(
                                  project,
                                  audioSourcePath: audioSourcePath,
                                ),
                      icon: previewState.isRendering
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.movie_creation_outlined),
                      label: Text(
                        previewState.hasRenderedResult
                            ? context.l10n.refreshRenderedPreview
                            : context.l10n.renderPreview,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Duration get _fallbackDuration {
    if (project?.beatMap.beats.isNotEmpty ?? false) {
      final beatMap = project!.beatMap;
      return beatMap.beats.last.time + beatMap.averageBeatInterval;
    }
    return const Duration(seconds: 30);
  }

  double _progress(Duration currentTime, Duration duration, double frameValue) {
    if (duration <= Duration.zero) {
      return frameValue.clamp(0, 1);
    }
    return (currentTime.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }
}

class CompositionPreviewCanvas extends StatelessWidget {
  const CompositionPreviewCanvas({
    required this.frame,
    required this.template,
    super.key,
  });
  final EditorPreviewFrame frame;
  final VideoTemplate? template;

  @override
  Widget build(BuildContext context) {
    final transition = frame.transition;
    final outgoing = frame.transitionOutgoing;
    final incoming = frame.transitionIncoming;
    if (template == null ||
        transition == null ||
        outgoing == null ||
        incoming == null) {
      return _ClipVisual(
        clip: frame.activeClip,
        template: template,
        time: frame.currentTime,
        evaluatedLayer: frame.compositionFrame?.layers.lastOrNull,
      );
    }
    final progress = frame.transitionProgress;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final first = _ClipVisual(
            clip: outgoing,
            template: template,
            time: frame.currentTime,
            evaluatedLayer: frame.compositionFrame?.layers.firstOrNull,
          );
          final second = _ClipVisual(
            clip: incoming,
            template: template,
            time: frame.currentTime,
            evaluatedLayer: frame.compositionFrame?.layers.lastOrNull,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              if (transition.type == ClipTransitionType.slide)
                Transform.translate(
                  offset: Offset(-constraints.maxWidth * progress, 0),
                  child: first,
                )
              else
                first,
              if (transition.type == ClipTransitionType.slide)
                Transform.translate(
                  offset: Offset(constraints.maxWidth * (1 - progress), 0),
                  child: second,
                )
              else
                Opacity(opacity: progress, child: second),
            ],
          );
        },
      ),
    );
  }
}

class _ClipVisual extends StatelessWidget {
  const _ClipVisual({
    required this.clip,
    required this.template,
    required this.time,
    this.evaluatedLayer,
  });
  final MediaTrackClipPayload? clip;
  final VideoTemplate? template;
  final Duration time;
  final CompositionLayer? evaluatedLayer;

  @override
  Widget build(BuildContext context) {
    final clip = this.clip;
    final template = this.template;
    if (clip == null || template == null) {
      return _PreviewSurface(activeClip: clip);
    }
    final layer = evaluatedLayer;
    final span = clip.end - clip.start;
    final progress =
        layer?.progress ??
        (span <= Duration.zero
            ? 0.0
            : ((time - clip.start).inMicroseconds / span.inMicroseconds).clamp(
                0.0,
                1.0,
              ));
    final motion = clip.motionFor(template);
    final zoom = layer?.motionZoom ?? motion.zoomAt(progress);
    final horizontalAnchor =
        layer?.horizontalAnchor ??
        motion.horizontalAnchorAt(progress, clip.cropTransform.focalX);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: zoom,
            alignment: Alignment(
              horizontalAnchor * 2 - 1,
              clip.cropTransform.focalY,
            ),
            child: _PreviewSurface(activeClip: clip),
          ),
        ),
        if (clip.caption.isNotEmpty || clip.captionSupportingLine.isNotEmpty)
          _CaptionPreview(
            clip: clip,
            template: template,
            time: time,
            resolvedFrame: layer?.captionFrame,
            resolvedLayout: layer?.captionLayout,
          ),
      ],
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.activeClip});

  final MediaTrackClipPayload? activeClip;

  @override
  Widget build(BuildContext context) {
    final path = activeClip?.sourcePath;
    if (path != null && path.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final decodeWidth =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 1536);
          return ColoredBox(
            color: context.colors.scrim,
            child: Image.file(
              File(path),
              cacheWidth: decodeWidth,
              fit: activeClip?.imageFit == VideoTemplateImageFit.contain
                  ? BoxFit.contain
                  : BoxFit.cover,
              alignment: Alignment(
                activeClip!.cropTransform.focalX,
                activeClip!.cropTransform.focalY,
              ),
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (activeClip!.imageFit == VideoTemplateImageFit.contain) {
                  return child;
                }
                return Transform.scale(
                  scale: activeClip!.cropTransform.zoom,
                  alignment: Alignment(
                    activeClip!.cropTransform.focalX,
                    activeClip!.cropTransform.focalY,
                  ),
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _FallbackPreview(title: activeClip?.title);
              },
            ),
          );
        },
      );
    }
    return _FallbackPreview(title: activeClip?.title);
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title ?? 'Sequence preview',
              style: context.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionPreview extends StatelessWidget {
  const _CaptionPreview({
    required this.clip,
    required this.template,
    required this.time,
    this.resolvedFrame,
    this.resolvedLayout,
  });

  final MediaTrackClipPayload clip;
  final VideoTemplate template;
  final Duration time;
  final CaptionFrame? resolvedFrame;
  final CaptionLayout? resolvedLayout;

  @override
  Widget build(BuildContext context) {
    final frame =
        resolvedFrame ??
        clip.captionSettings.evaluate(time - clip.start, clip.end - clip.start);
    if (!frame.visible) return const SizedBox.shrink();
    final ratio = template.aspectRatio;
    final layout =
        resolvedLayout ??
        CaptionLayout(
          title: clip.caption,
          supportingLine: clip.captionSupportingLine,
          template: template,
          settings: clip.captionSettings,
          width: ratio.exportWidth,
          height: ratio.exportHeight,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / layout.width;
        final slide = clip.captionSettings.entrance == CaptionEntrance.slide
            ? (layout.height / 30) * (1 - frame.entranceProgress) * scale
            : 0.0;
        final combined = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout.titleText.isNotEmpty)
              _CaptionLine(
                text: layout.titleText,
                size: layout.titleSize * scale,
                color: CaptionRenderColors.text(clip.captionSettings),
                isTitle: true,
                legacyBackdrop:
                    clip.captionSettings.backdrop == CaptionBackdrop.legacy,
              ),
            if (layout.gap > 0) SizedBox(height: layout.gap * scale),
            if (layout.supportText.isNotEmpty)
              _CaptionLine(
                text: layout.supportText,
                size: layout.supportSize * scale,
                color: CaptionRenderColors.text(clip.captionSettings),
                isTitle: false,
                legacyBackdrop:
                    clip.captionSettings.backdrop == CaptionBackdrop.legacy,
              ),
          ],
        );
        final hasPanel =
            clip.captionSettings.backdrop == CaptionBackdrop.panel ||
            clip.captionSettings.backdrop == CaptionBackdrop.strongPanel;
        final padding = (layout.titleSize / 2) * scale;
        return Stack(
          children: [
            Positioned(
              top: (layout.top * scale + slide) - (hasPanel ? padding : 0),
              left: constraints.maxWidth * 0.1,
              right: constraints.maxWidth * 0.1,
              child: Opacity(
                opacity: frame.opacity,
                child: hasPanel
                    ? ColoredBox(
                        color: CaptionRenderColors.backdrop(
                          clip.captionSettings,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: combined,
                        ),
                      )
                    : combined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CaptionLine extends StatelessWidget {
  const _CaptionLine({
    required this.text,
    required this.size,
    required this.color,
    required this.isTitle,
    required this.legacyBackdrop,
  });

  final String text;
  final double size;
  final Color color;
  final bool isTitle;
  final bool legacyBackdrop;

  @override
  Widget build(BuildContext context) {
    final caption = Text(
      text,
      textAlign: TextAlign.center,
      style:
          (isTitle
                  ? context.textTheme.titleMedium
                  : context.textTheme.bodyMedium)
              ?.copyWith(fontSize: size, color: color),
    );
    if (!legacyBackdrop) return caption;
    return ColoredBox(
      color: CaptionRenderColors.backdrop(const CaptionSettings()),
      child: caption,
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
