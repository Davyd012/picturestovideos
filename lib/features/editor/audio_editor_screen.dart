import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/editor/editor_preview_view_model.dart';
import 'package:picturestovideos/features/editor/editor_tab_state.dart';
import 'package:picturestovideos/features/editor/editor_tab_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/clips_tab_view.dart';
import 'package:picturestovideos/features/editor/widgets/editor_section_tab_bar.dart';
import 'package:picturestovideos/features/editor/widgets/markers_tab_view.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';
import 'package:picturestovideos/features/editor/widgets/playback_controls.dart';
import 'package:picturestovideos/features/editor/widgets/timeline_tab_view.dart';
import 'package:picturestovideos/features/editor/widgets/tools_tab_view.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioEditorScreen extends ConsumerStatefulWidget {
  const AudioEditorScreen({super.key});

  @override
  ConsumerState<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends ConsumerState<AudioEditorScreen> {
  late final ProviderSubscription<ProjectTimeline?> _timelineSubscription;
  Timer? _previewSyncDebounce;

  @override
  void initState() {
    super.initState();
    _timelineSubscription = ref.listenManual<ProjectTimeline?>(
      timelineViewModelProvider.select((next) => next.asData?.value.project),
      (_, nextProject) {
        _schedulePreviewSync(nextProject);
      },
    );
  }

  @override
  void dispose() {
    _previewSyncDebounce?.cancel();
    _timelineSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final timelineState = ref.watch(timelineViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);
    final eventState = ref.watch(eventSystemViewModelProvider);
    final importState = ref.watch(audioImportViewModelProvider);
    final mediaSelection = ref.watch(editorMediaSelectionViewModelProvider);
    final previewState = ref.watch(editorPreviewViewModelProvider);
    final selectedTab = ref.watch(editorTabViewModelProvider);

    final timeline = timelineState.asData?.value;
    final playback = playbackState.asData?.value;
    final events = eventState.asData?.value.events ?? const <BeatEvent>[];
    final importedAudio = importState.asData?.value;
    final beatMap = _resolvedBeatMap(
      beatMapState: beatMapState,
      timelineState: timelineState,
      playbackState: playbackState,
    );

    return AppShellScaffold(
      currentRoute: AppRoutes.audioEditor,
      title: 'Video editor',
      leading: IconButton(
        onPressed: () => context.appNavigator.maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: beatMap == null
                ? null
                : () => context.appNavigator.goToDownload(),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export'),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MobileEditorPreviewCard(
            beatMap: beatMap,
            project: timeline?.project,
            playback: playback,
            previewState: previewState,
          ),
          const SizedBox(height: 12),
          EditorSectionTabBar(
            selectedTab: selectedTab,
            onTabSelected: (tab) =>
                ref.read(editorTabViewModelProvider.notifier).tabSelected(tab),
          ),
          const SizedBox(height: 12),
          PlaybackControls(
            beatMap: beatMap,
            playback: playback,
            audioSourcePath: importedAudio?.source?.path,
          ),
          const SizedBox(height: 16),
          _EditorTabBody(
            selectedTab: selectedTab,
            beatMap: beatMap,
            timeline: timeline,
            playback: playback,
            events: events,
            eventState: eventState,
            selectedMedia: mediaSelection.selectedMedia,
            audioDuration: importedAudio?.audioData?.duration,
            audioSourcePath: importedAudio?.source?.path,
          ),
        ],
      ),
    );
  }

  void _schedulePreviewSync(ProjectTimeline? project) {
    if (project == null) {
      return;
    }
    _previewSyncDebounce?.cancel();
    _previewSyncDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref
          .read(editorPreviewViewModelProvider.notifier)
          .syncPreview(
            project,
            audioSourcePath: _audioSourcePath,
            reason: 'timeline listener',
          );
    });
  }

  String? get _audioSourcePath => ref.read(
    audioImportViewModelProvider.select(
      (next) => next.asData?.value.source?.path,
    ),
  );

  BeatMap? _resolvedBeatMap({
    required AsyncValue<BeatMapState> beatMapState,
    required AsyncValue<TimelineState> timelineState,
    required AsyncValue<PlaybackState> playbackState,
  }) {
    final projectBeatMap = timelineState.asData?.value.project?.beatMap;
    if (projectBeatMap != null) {
      return projectBeatMap;
    }
    final playbackBeatMap = playbackState.asData?.value.beatMap;
    if (playbackBeatMap != null && playbackBeatMap.beats.isNotEmpty) {
      return playbackBeatMap;
    }
    final stateBeatMap = beatMapState.asData?.value.beatMap;
    if (stateBeatMap != null && stateBeatMap.beats.isNotEmpty) {
      return stateBeatMap;
    }
    return null;
  }
}

class _EditorTabBody extends ConsumerWidget {
  const _EditorTabBody({
    required this.selectedTab,
    required this.beatMap,
    required this.timeline,
    required this.playback,
    required this.events,
    required this.eventState,
    required this.selectedMedia,
    required this.audioDuration,
    required this.audioSourcePath,
  });

  final EditorTab selectedTab;
  final BeatMap? beatMap;
  final TimelineState? timeline;
  final PlaybackState? playback;
  final List<BeatEvent> events;
  final AsyncValue<EventSystemState> eventState;
  final List<LibraryMediaItem> selectedMedia;
  final Duration? audioDuration;
  final String? audioSourcePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (selectedTab) {
      EditorTab.timeline => TimelineTabView(
        beatMap: beatMap,
        project: timeline?.project,
        playback: playback,
        selectedMedia: selectedMedia,
        events: events,
        onCurrentPointChanged: (position) => _seekTo(ref, position),
      ),
      EditorTab.clips => ClipsTabView(
        selectedMedia: selectedMedia,
        onOpenTimeline: () => ref
            .read(editorTabViewModelProvider.notifier)
            .tabSelected(EditorTab.timeline),
      ),
      EditorTab.markers => MarkersTabView(
        beatMap: beatMap,
        project: timeline?.project,
        events: events,
        selectedMarker: timeline?.selectedMarker,
        onAddMarker: () => _addMarkerAtCurrentPoint(ref),
        onDeleteMarker: () => ref
            .read(timelineViewModelProvider.notifier)
            .deleteSelectedImageMarker(),
        onMarkerSelected: (time) async {
          ref
              .read(timelineViewModelProvider.notifier)
              .selectImageMarker(time: time);
          await _seekTo(ref, time);
        },
      ),
      EditorTab.tools => ToolsTabView(
        beatMap: beatMap,
        project: timeline?.project,
        playback: playback,
        selectedTemplate:
            timeline?.selectedTemplate ?? VideoTemplates.cleanMemories,
        selectedMedia: selectedMedia,
        selectedMarker: timeline?.selectedMarker,
        events: events,
        eventStatusText: _eventStatusText(eventState),
        audioDuration: audioDuration,
        onAddMarker: () => _addMarkerAtCurrentPoint(ref),
        onAddImagePoint: () => _addManualImagePointAtCurrentPoint(ref),
        onDeleteMarker: () => ref
            .read(timelineViewModelProvider.notifier)
            .deleteSelectedImageMarker(),
      ),
    };
  }

  Future<void> _seekTo(WidgetRef ref, Duration position) async {
    final resolvedBeatMap = beatMap;
    if (resolvedBeatMap == null) {
      return;
    }
    await ref
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap: resolvedBeatMap,
          audioSourcePath: audioSourcePath,
        );
    await ref.read(playbackViewModelProvider.notifier).seek(position);
  }

  void _addMarkerAtCurrentPoint(WidgetRef ref) {
    final resolvedBeatMap = beatMap;
    if (resolvedBeatMap == null) {
      return;
    }
    ref
        .read(timelineViewModelProvider.notifier)
        .addImageMarkerAt(
          time: playback?.currentTime ?? Duration.zero,
          beatMap: resolvedBeatMap,
          fallbackMarkerEvents: events,
        );
  }

  void _addManualImagePointAtCurrentPoint(WidgetRef ref) {
    ref
        .read(timelineViewModelProvider.notifier)
        .addManualImagePointAt(
          time: playback?.currentTime ?? Duration.zero,
          beatMap: beatMap,
          selectedMedia: selectedMedia,
          audioDuration: audioDuration,
        );
  }
}

String _eventStatusText(AsyncValue<EventSystemState> eventState) {
  return switch (eventState) {
    AsyncLoading<EventSystemState>() => 'Preparing event dispatch state.',
    AsyncError<EventSystemState>(:final error) => error.toString(),
    AsyncData<EventSystemState>(:final value) when value.hasEvents =>
      'Next event index ${value.nextEventIndex} with ${value.executions.length} executions recorded.',
    _ => 'Next event index 5 with 5 executions recorded.',
  };
}
