import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_clip_selection_view_model.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_controls.dart';
import 'package:picturestovideos/features/editor/widgets/editor_filmstrip.dart';
import 'package:picturestovideos/features/editor/widgets/empty_editor_state.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class MobileEditorScreen extends ConsumerWidget {
  const MobileEditorScreen({
    super.key,
    required this.project,
    required this.beatMap,
    required this.audioPath,
    required this.queueCount,
    required this.canExport,
    required this.openAdvanced,
  });
  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final String? audioPath;
  final int queueCount;
  final bool canExport;
  final ValueChanged<EditorTab> openAdvanced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clips = project == null
        ? <MediaTrackClipPayload>[]
        : ref
              .read(resolvePreviewClipsUseCaseProvider)
              .call(beatMap: project!.beatMap, project: project);
    final selectedId = ref
        .watch(editorClipSelectionViewModelProvider)
        .selectedClipId;
    final selected =
        clips.where((clip) => clip.clipId == selectedId).firstOrNull ??
        clips.firstOrNull;
    final duration = project?.videoDuration ?? Duration.zero;
    final canPlay = audioPath?.isNotEmpty ?? false;
    Future<void> prepare() async => ref
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap:
              beatMap ??
              const BeatMap(
                beats: [],
                bpm: 0,
                averageBeatInterval: Duration.zero,
              ),
          audioSourcePath: audioPath,
          audioMix: project?.audioMix ?? const AudioMix(),
          videoDuration: project?.videoDuration,
        );
    Future<void> seek(Duration position) async {
      await prepare();
      await ref.read(playbackViewModelProvider.notifier).seek(position);
    }

    void settings(ImageSettingsSection section) {
      if (selected != null) {
        context.appNavigator.goToImageSettings(
          selected.clipId,
          section: section,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () async {
            final navigator = context.appNavigator;
            if (!await navigator.maybePop()) {
              navigator.goToHome(replace: true);
            }
          },
        ),
        title: Text(
          context.l10n.navEditor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (clips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: canExport
                    ? () => context.appNavigator.goToDownload()
                    : null,
                icon: const Icon(Icons.ios_share),
                label: Text(context.l10n.navExport),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: clips.isEmpty
              ? EmptyEditorState(
                  key: const ValueKey('empty'),
                  hasQueuedImages: queueCount > 0,
                  onAdd: () => queueCount > 0
                      ? context.appNavigator.goToEditorQueue()
                      : context.appNavigator.goToLibrary(),
                )
              : LayoutBuilder(
                  key: const ValueKey('workspace'),
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 500;
                    final availableHeight = constraints.maxHeight < 400
                        ? 520.0
                        : constraints.maxHeight;
                    final previewHeight = math.min(
                      availableHeight * (compact ? 0.34 : 0.40),
                      constraints.maxWidth /
                          (project?.template.aspectRatio.value ?? 16 / 9),
                    );
                    final workspace = Column(
                      children: [
                        SizedBox(
                          height: previewHeight,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio:
                                  project?.template.aspectRatio.value ?? 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _AnimatedPreview(
                                    project: project,
                                    beatMap: beatMap,
                                  ),
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    child: Material(
                                      color: context.colors.surface,
                                      child: IconButton(
                                        onPressed: () => showDialog<void>(
                                          context: context,
                                          builder: (_) => _FullscreenPreview(
                                            project: project,
                                            beatMap: beatMap,
                                          ),
                                        ),
                                        icon: const Icon(Icons.fullscreen),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: ColoredBox(
                                      color: context.colors.surface,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          project?.template.aspectRatio.label ??
                                              '16:9',
                                          style: context.textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        EditorPlaybackBar(
                          duration: duration,
                          canPlay: canPlay,
                          onSeek: (value) => seek(value),
                          onPlay: () async {
                            await prepare();
                            final vm = ref.read(
                              playbackViewModelProvider.notifier,
                            );
                            if (ref
                                    .read(playbackViewModelProvider)
                                    .asData
                                    ?.value
                                    .isPlaying ??
                                false) {
                              await vm.pause();
                            } else {
                              await vm.play();
                            }
                          },
                          onFullscreen: () => showDialog<void>(
                            context: context,
                            builder: (context) => _FullscreenPreview(
                              project: project,
                              beatMap: beatMap,
                            ),
                          ),
                          onVolume: () => openAdvanced(EditorTab.tools),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.selected,
                                  style: context.textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${clips.indexOf(selected!) + 1} / ${clips.length}',
                                style: context.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: EditorWorkspaceTab(
                                label: context.l10n.editorClips,
                                count: clips.length,
                                selected: true,
                                onTap: () {},
                              ),
                            ),
                            Expanded(
                              child: EditorWorkspaceTab(
                                label: context.l10n.editorQueue,
                                count: queueCount,
                                selected: false,
                                onTap: () =>
                                    context.appNavigator.goToEditorQueue(),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          flex: 3,
                          child: EditorFilmstrip(
                            clips: clips,
                            selectedId: selected.clipId,
                            audioPath: audioPath,
                            onSelect: (clip) {
                              ref
                                  .read(
                                    editorClipSelectionViewModelProvider
                                        .notifier,
                                  )
                                  .clipSelected(clip.clipId);
                              seek(clip.start);
                            },
                            onEditClip: (clip) {
                              ref
                                  .read(
                                    editorClipSelectionViewModelProvider
                                        .notifier,
                                  )
                                  .clipSelected(clip.clipId);
                              context.appNavigator.goToImageSettings(
                                clip.clipId,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex < clips.length &&
                                  newIndex < clips.length) {
                                ref
                                    .read(timelineViewModelProvider.notifier)
                                    .clipMoved(
                                      clipId: clips[oldIndex].clipId,
                                      position: newIndex + 1,
                                    );
                              }
                            },
                            onAdd: () => context.appNavigator.goToEditorQueue(),
                          ),
                        ),
                        EditorToolbar(
                          enabled: true,
                          onSettings: settings,
                          onAudio: () => context.appNavigator.goToAudioEditor(),
                        ),
                      ],
                    );
                    if (constraints.maxHeight < 400) {
                      return SingleChildScrollView(
                        child: SizedBox(height: 520, child: workspace),
                      );
                    }
                    return workspace;
                  },
                ),
        ),
      ),
    );
  }
}

class _FullscreenPreview extends ConsumerWidget {
  const _FullscreenPreview({required this.project, required this.beatMap});
  final ProjectTimeline? project;
  final BeatMap? beatMap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: project?.template.aspectRatio.value ?? 16 / 9,
                child: _AnimatedPreview(project: project, beatMap: beatMap),
              ),
            ),
            const Align(alignment: Alignment.topRight, child: CloseButton()),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPreview extends ConsumerStatefulWidget {
  const _AnimatedPreview({required this.project, required this.beatMap});

  final ProjectTimeline? project;
  final BeatMap? beatMap;

  @override
  ConsumerState<_AnimatedPreview> createState() => _AnimatedPreviewState();
}

class _AnimatedPreviewState extends ConsumerState<_AnimatedPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Stopwatch _elapsed = Stopwatch();
  Duration _anchor = Duration.zero;
  Duration? _lastAudioTime;
  Duration _displayTime = Duration.zero;
  String? _preloadedPath;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (!mounted) return;
      setState(() => _displayTime = _anchor + _elapsed.elapsed);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackViewModelProvider).asData?.value;
    final audioTime = playback?.currentTime ?? Duration.zero;
    if (_lastAudioTime != audioTime || _lastAudioTime == null) {
      _lastAudioTime = audioTime;
      _anchor = audioTime;
      _displayTime = audioTime;
      if (_elapsed.isRunning) {
        _elapsed
          ..stop()
          ..reset()
          ..start();
      }
    }
    if (playback?.isPlaying ?? false) {
      if (!_ticker.isActive) {
        _anchor = audioTime;
        _displayTime = audioTime;
        _elapsed
          ..reset()
          ..start();
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
      _elapsed
        ..stop()
        ..reset();
      _displayTime = audioTime;
    }

    final frame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(
          beatMap: widget.beatMap,
          project: widget.project,
          currentTime: _displayTime,
        );
    final nextPath = frame.nextClip?.sourcePath;
    if (nextPath != null && nextPath.isNotEmpty && nextPath != _preloadedPath) {
      _preloadedPath = nextPath;
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final decodeWidth = (MediaQuery.sizeOf(context).width * pixelRatio)
          .round()
          .clamp(1, 1536);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _preloadedPath != nextPath) return;
        final provider = ResizeImage(
          FileImage(File(nextPath)),
          width: decodeWidth,
        );
        precacheImage(provider, context);
      });
    }
    return RepaintBoundary(
      child: CompositionPreviewCanvas(
        frame: frame,
        template: widget.project?.template,
      ),
    );
  }
}
