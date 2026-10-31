import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/application/resolve_editor_preview_frame_use_case.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_clip_selection_view_model.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';
import 'package:picturestovideos/features/editor/editor_tab_label.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_controls.dart';
import 'package:picturestovideos/features/editor/widgets/editor_filmstrip.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
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
    required this.playback,
    required this.audioPath,
    required this.queueCount,
    required this.canExport,
    required this.openAdvanced,
  });
  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final PlaybackState? playback;
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
    final frame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(
          beatMap: beatMap,
          project: project,
          currentTime: playback?.currentTime ?? Duration.zero,
        );
    final selectedId = ref
        .watch(editorClipSelectionViewModelProvider)
        .selectedClipId;
    final selected = clips
        .where((clip) => clip.clipId == selectedId)
        .firstOrNull;
    final duration =
        project?.videoDuration ?? playback?.sourceDuration ?? Duration.zero;
    final current = playback?.currentTime ?? Duration.zero;
    final canPlay =
        (audioPath?.isNotEmpty ?? false) ||
        (playback?.hasLoadedAudioSource ?? false);
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

    void settings() {
      if (selected != null) {
        context.appNavigator.goToImageSettings(selected.clipId);
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
        child: LayoutBuilder(
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
                          CompositionPreviewCanvas(
                            frame: frame,
                            template: project?.template,
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
                                  project?.template.aspectRatio.label ?? '16:9',
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
                  current: current,
                  duration: duration,
                  canPlay: canPlay,
                  playing: playback?.isPlaying ?? false,
                  onSeek: (value) => seek(value),
                  onPlay: () async {
                    await prepare();
                    final vm = ref.read(playbackViewModelProvider.notifier);
                    if (playback?.isPlaying ?? false) {
                      await vm.pause();
                    } else {
                      await vm.play();
                    }
                  },
                  onFullscreen: () => showDialog<void>(
                    context: context,
                    builder: (context) =>
                        _FullscreenPreview(project: project, beatMap: beatMap),
                  ),
                  onVolume: () => openAdvanced(EditorTab.tools),
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
                        onTap: () => context.appNavigator.goToEditorQueue(),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  flex: 3,
                  child: EditorFilmstrip(
                    clips: clips,
                    selectedId: selectedId,
                    current: current,
                    audioPath: audioPath,
                    onSelect: (clip) {
                      ref
                          .read(editorClipSelectionViewModelProvider.notifier)
                          .clipSelected(clip.clipId);
                      seek(clip.start);
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < clips.length && newIndex < clips.length) {
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
                  enabled: selected != null,
                  onSettings: settings,
                  onMore: () => _showMore(context),
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
    );
  }

  void _showMore(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in EditorTab.values)
            ListTile(
              title: Text(editorTabLabel(context, tab)),
              onTap: () {
                Navigator.pop(context);
                openAdvanced(tab);
              },
            ),
        ],
      ),
    ),
  );
}

class _FullscreenPreview extends ConsumerWidget {
  const _FullscreenPreview({required this.project, required this.beatMap});
  final ProjectTimeline? project;
  final BeatMap? beatMap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time =
        ref.watch(playbackViewModelProvider).asData?.value.currentTime ??
        Duration.zero;
    final frame = ref
        .read(resolveEditorPreviewFrameUseCaseProvider)
        .call(beatMap: beatMap, project: project, currentTime: time);
    return Dialog.fullscreen(
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: project?.template.aspectRatio.value ?? 16 / 9,
                child: CompositionPreviewCanvas(
                  frame: frame,
                  template: project?.template,
                ),
              ),
            ),
            const Align(alignment: Alignment.topRight, child: CloseButton()),
          ],
        ),
      ),
    );
  }
}
