import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class MobileEditorPreviewCard extends ConsumerWidget {
  const MobileEditorPreviewCard({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.previewState,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final EditorPreviewState previewState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewFrame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(
          beatMap: beatMap,
          project: project,
          currentTime: playback?.currentTime ?? Duration.zero,
        );
    final activeClip = previewFrame.activeClip;
    final duration = previewState.result?.totalDuration ?? _fallbackDuration;
    final currentTime = playback?.currentTime ?? Duration.zero;
    final progress = _progress(currentTime, duration, previewFrame.progress);
    final aspectRatio = project?.template.aspectRatio.value ?? 16 / 9;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PreviewSurface(activeClip: activeClip),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.colors.scrim.withValues(alpha: 0.08),
                        context.colors.scrim.withValues(alpha: 0.54),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Badge(
                            label: previewFrame.hasActiveClip
                                ? '${previewFrame.activeIndex + 1} / ${previewFrame.clips.length}'
                                : _statusLabel,
                          ),
                          const SizedBox(width: 8),
                          if (activeClip != null)
                            Expanded(child: _Badge(label: activeClip.title)),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: IconButton.filledTonal(
                          onPressed: null,
                          iconSize: 32,
                          icon: Icon(
                            playback?.isPlaying ?? false
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activeClip?.tagline ?? 'Live sequence preview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _Badge(
                            label:
                                '${_formatDuration(currentTime)} / ${_formatDuration(duration)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(value: progress, minHeight: 6),
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

  String get _statusLabel {
    if (beatMap == null) {
      return 'No markers';
    }
    return switch (previewState.status) {
      EditorPreviewStatus.rendering => 'Rendering',
      EditorPreviewStatus.ready => 'Ready',
      EditorPreviewStatus.failure => 'Unavailable',
      _ => '${beatMap!.beats.length} markers',
    };
  }

  double _progress(Duration currentTime, Duration duration, double frameValue) {
    if (duration <= Duration.zero) {
      return frameValue.clamp(0, 1);
    }
    return (currentTime.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.activeClip});

  final MediaTrackClipPayload? activeClip;

  @override
  Widget build(BuildContext context) {
    final path = activeClip?.sourcePath;
    if (path != null && path.isNotEmpty) {
      return ColoredBox(
        color: context.colors.scrim,
        child: Image.file(
          File(path),
          fit: activeClip?.imageFit == VideoTemplateImageFit.contain
              ? BoxFit.contain
              : BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackPreview(title: activeClip?.title);
          },
        ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
