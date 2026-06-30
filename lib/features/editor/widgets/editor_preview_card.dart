import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_preview_state.dart';
import 'package:picturestovideos/features/editor/editor_preview_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class EditorPreviewCard extends ConsumerStatefulWidget {
  const EditorPreviewCard({
    super.key,
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.audioSourcePath,
    required this.previewState,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final String? audioSourcePath;
  final EditorPreviewState previewState;

  @override
  ConsumerState<EditorPreviewCard> createState() => _EditorPreviewCardState();
}

class _EditorPreviewCardState extends ConsumerState<EditorPreviewCard> {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);
  String? _loadedPreviewPath;
  Duration _previewPosition = Duration.zero;
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.stream.position.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPosition = position;
      });
    });
    _player.stream.playing.listen((playing) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewPlaying = playing;
      });
    });
    _syncVideoSource();
  }

  @override
  void didUpdateWidget(covariant EditorPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewState.result?.outputPath !=
        widget.previewState.result?.outputPath) {
      _syncVideoSource();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewFrame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(
          beatMap: widget.beatMap,
          project: widget.project,
          currentTime: _activePreviewTime,
        );
    final hasVideoSurface =
        widget.previewState.isReady &&
        _loadedPreviewPath != null &&
        _loadedPreviewPath == widget.previewState.result?.outputPath;
    final canRenderVideo =
        widget.project != null && !widget.previewState.isRendering;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: widget.project?.template.aspectRatio.value ?? 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideoSurface)
              Video(controller: _videoController, fit: BoxFit.cover)
            else if (previewFrame.hasActiveClip)
              _LivePreviewSurface(previewFrame: previewFrame)
            else
              ColoredBox(color: context.colors.surfaceContainerHighest),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.scrim.withValues(alpha: 0.12),
                    context.colors.scrim.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Chip(
                        label: Text(
                          _statusLabel(widget.previewState, widget.beatMap),
                        ),
                      ),
                      if (previewFrame.hasActiveClip)
                        Chip(
                          label: Text(
                            '${previewFrame.activeIndex + 1} / ${previewFrame.clips.length}',
                          ),
                        ),
                      if (widget.previewState.result != null)
                        Chip(
                          label: Text(
                            _formatDuration(
                              widget.previewState.result!.totalDuration,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.previewState.statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.outlineVariant,
                        ),
                      ),
                      child: Text(
                        widget.previewState.statusMessage!,
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: canRenderVideo
                            ? () => ref
                                  .read(editorPreviewViewModelProvider.notifier)
                                  .renderPreview(
                                    widget.project,
                                    audioSourcePath: widget.audioSourcePath,
                                  )
                            : null,
                        icon: const Icon(Icons.movie_creation_outlined),
                        label: const Text('Render video'),
                      ),
                      FilledButton.icon(
                        onPressed: widget.previewState.isReady
                            ? () => _playPreview()
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play rendered video'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.previewState.isReady
                            ? () => _stopPreview()
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop video'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _playAvailabilityMessage(widget.previewState),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!previewFrame.hasActiveClip)
                    _EmptyPreviewCopy(
                      beatMap: widget.beatMap,
                      previewState: widget.previewState,
                    )
                  else
                    _ActivePreviewCopy(
                      previewFrame: previewFrame,
                      previewState: widget.previewState,
                      isPreviewPlaying: _isPreviewPlaying,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration get _activePreviewTime {
    if (_isPreviewPlaying) {
      return _previewPosition;
    }
    return widget.playback?.currentTime ?? Duration.zero;
  }

  Future<void> _syncVideoSource() async {
    final previewPath = widget.previewState.result?.outputPath;
    if (previewPath == null || previewPath == _loadedPreviewPath) {
      return;
    }

    await _player.open(Media(previewPath), play: false);
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedPreviewPath = previewPath;
      _previewPosition = Duration.zero;
    });
  }

  Future<void> _playPreview() async {
    final result = widget.previewState.result;
    if (result == null) {
      return;
    }
    await _syncVideoSource();
    await _player.seek(
      _previewPosition >= result.totalDuration
          ? Duration.zero
          : _previewPosition,
    );
    await _player.play();
  }

  Future<void> _stopPreview() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    if (mounted) {
      setState(() {
        _previewPosition = Duration.zero;
      });
    }
  }

  String _statusLabel(EditorPreviewState previewState, BeatMap? beatMap) {
    if (beatMap == null) {
      return 'Awaiting beat map';
    }
    return switch (previewState.status) {
      EditorPreviewStatus.rendering => 'Rendering image preview',
      EditorPreviewStatus.ready => 'Image preview ready',
      EditorPreviewStatus.live => 'Live image preview',
      EditorPreviewStatus.failure => 'Preview unavailable',
      _ => 'Marker-synced image preview',
    };
  }

  String _playAvailabilityMessage(EditorPreviewState previewState) {
    if (previewState.isReady) {
      return 'Preview video is loaded and ready to play.';
    }
    if (previewState.isLive) {
      return 'Live preview is ready. Render video only when you need a playable file.';
    }
    if (previewState.isRendering) {
      return 'Play video is disabled until the image preview finishes rendering.';
    }
    if (previewState.isFailure) {
      return previewState.errorMessage ??
          'Play video is disabled because preview generation failed.';
    }
    return previewState.statusMessage ??
        'Play video is disabled until preview generation starts.';
  }
}

class _ActivePreviewCopy extends StatelessWidget {
  const _ActivePreviewCopy({
    required this.previewFrame,
    required this.previewState,
    required this.isPreviewPlaying,
  });

  final EditorPreviewFrame previewFrame;
  final EditorPreviewState previewState;
  final bool isPreviewPlaying;

  @override
  Widget build(BuildContext context) {
    final activeClip = previewFrame.activeClip!;
    final progress = previewFrame.progress.clamp(0.0, 1.0);
    final videoPath = previewState.result?.outputPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeClip.title,
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          activeClip.tagline.isEmpty
              ? 'Marker-synced image clip'
              : activeClip.tagline,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                previewFrame.nextClip == null
                    ? 'Final clip in preview'
                    : 'Next: ${previewFrame.nextClip!.title}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${isPreviewPlaying ? 'Preview' : 'Playhead'} ${_formatDuration(previewFrame.currentTime)}',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
          ],
        ),
        if (previewState.result != null) ...[
          const SizedBox(height: 8),
          Text(
            videoPath ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LivePreviewSurface extends StatelessWidget {
  const _LivePreviewSurface({required this.previewFrame});

  final EditorPreviewFrame previewFrame;

  @override
  Widget build(BuildContext context) {
    final activeClip = previewFrame.activeClip!;
    final sourcePath = activeClip.sourcePath;
    if (sourcePath.isEmpty) {
      return _MissingLivePreviewSurface(title: activeClip.title);
    }

    return ColoredBox(
      color: context.colors.scrim,
      child: Image.file(
        File(sourcePath),
        fit: _livePreviewFit(activeClip.imageFit),
        errorBuilder: (context, error, stackTrace) {
          return _MissingLivePreviewSurface(title: activeClip.title);
        },
      ),
    );
  }
}

BoxFit _livePreviewFit(VideoTemplateImageFit imageFit) {
  if (imageFit == VideoTemplateImageFit.cover) {
    return BoxFit.cover;
  }
  return BoxFit.contain;
}

class _MissingLivePreviewSurface extends StatelessWidget {
  const _MissingLivePreviewSurface({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreviewCopy extends StatelessWidget {
  const _EmptyPreviewCopy({required this.beatMap, required this.previewState});

  final BeatMap? beatMap;
  final EditorPreviewState previewState;

  @override
  Widget build(BuildContext context) {
    final description = switch (previewState.status) {
      EditorPreviewStatus.rendering =>
        'Marker-synced image segments are rendering now.',
      EditorPreviewStatus.live =>
        'Live preview follows the playhead without rendering a video file.',
      EditorPreviewStatus.failure =>
        previewState.errorMessage ??
            'The image preview could not be generated on this device.',
      _ when beatMap == null =>
        'Import audio, build the beat map, then sync images to render the preview.',
      _ =>
        'Queue images from the library and run auto-sync to create the preview track.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          previewState.isFailure
              ? Icons.warning_amber_outlined
              : Icons.movie_outlined,
          size: 48,
          color: context.colors.onPrimary,
        ),
        const SizedBox(height: 16),
        Text(
          projectTitle(beatMap),
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
      ],
    );
  }

  String projectTitle(BeatMap? beatMap) {
    if (beatMap == null) {
      return 'Preview waiting for beat-aware data';
    }
    return '${beatMap.beats.length} markers ready for preview';
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final millis = (duration.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds:$millis';
}
