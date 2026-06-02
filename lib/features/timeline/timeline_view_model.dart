import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/build_project_timeline_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';

final timelineViewModelProvider =
    AsyncNotifierProvider<TimelineViewModel, TimelineState>(
      TimelineViewModel.new,
    );

class TimelineViewModel extends AsyncNotifier<TimelineState> {
  static const _tag = 'TimelineViewModel';

  @override
  Future<TimelineState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing timeline state');
    return const TimelineState.initial();
  }

  Future<void> buildProjectTimeline({
    required BeatMap beatMap,
    required List<BeatEvent> events,
    List<LibraryMediaItem> selectedMedia = const [],
  }) async {
    final currentState = _currentState;
    final currentProject = currentState.project;
    final markerEvents = _resolveMarkerEvents(
      currentProject: currentProject,
      fallbackEvents: events,
    );
    ref
        .read(appLoggerProvider)
        .info(
          _tag,
          'Building timeline from ${markerEvents.length} markers and ${selectedMedia.length} media items',
        );
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final project = ref
          .read(buildProjectTimelineUseCaseProvider)
          .call(
            beatMap: beatMap,
            events: markerEvents,
            selectedMedia: selectedMedia,
            template: currentState.selectedTemplate,
          );
      final serializedProject = ref
          .read(projectSerializerProvider)
          .serialize(project);
      ref
          .read(appLoggerProvider)
          .info(_tag, 'Timeline ready with ${project.tracks.length} tracks');

      return TimelineState(
        project: project,
        serializedProject: serializedProject,
        selectedMarker: null,
        nextQueuedMediaIndex: 0,
        selectedTemplate: currentState.selectedTemplate,
      );
    });
  }

  void templateSelected(VideoTemplate template) {
    final currentState = _currentState;
    final currentProject = currentState.project;
    final updatedProject = currentProject?.copyWith(template: template);

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: updatedProject == null
            ? currentState.serializedProject
            : _serialize(updatedProject),
        selectedTemplate: template,
      ),
    );
  }

  void addImageMarkerAt({
    required Duration time,
    required BeatMap beatMap,
    required List<BeatEvent> fallbackMarkerEvents,
  }) {
    final currentState = _currentState;
    final project =
        currentState.project ??
        ref
            .read(buildProjectTimelineUseCaseProvider)
            .call(
              beatMap: beatMap,
              events: fallbackMarkerEvents,
              template: currentState.selectedTemplate,
            );
    final markerEvent = BeatEvent(
      time: time,
      type: 'marker',
      payload: 'Marker ${_markerCount(project.tracks) + 1}',
    );
    final updatedProject = project.copyWith(
      beatMap: beatMap,
      tracks: _upsertMarkerTrack(
        tracks: project.tracks,
        markerEvent: markerEvent,
      ),
    );

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        selectedMarker: TimelineMarkerSelection(time: time),
      ),
    );
  }

  void addManualImagePointAt({
    required Duration time,
    required BeatMap? beatMap,
    required List<LibraryMediaItem> selectedMedia,
    required Duration? audioDuration,
  }) {
    if (selectedMedia.isEmpty) {
      return;
    }

    final currentState = _currentState;
    final project =
        currentState.project ??
        ProjectTimeline(
          id: 'project-main',
          name: 'Picture To Videos Project',
          beatMap: beatMap ?? _manualBeatMap(audioDuration),
          tracks: const [
            TimelineTrack(id: 'track-markers', name: 'Markers', events: []),
          ],
          template: currentState.selectedTemplate,
        );
    final mediaIndex = currentState.nextQueuedMediaIndex % selectedMedia.length;
    final item = selectedMedia[mediaIndex];
    final markerEvent = BeatEvent(
      time: time,
      type: 'marker',
      payload: item.title,
    );
    final mediaEvent = BeatEvent(
      time: time,
      type: 'image',
      payload: MediaTrackClipPayload(
        mediaId: item.id,
        title: item.title,
        tagline: item.tagline,
        start: time,
        end: time + _manualClipSpan(project.beatMap),
        sourcePath: item.sourcePath,
      ),
    );
    final tracksWithMarker = _upsertMarkerTrack(
      tracks: project.tracks,
      markerEvent: markerEvent,
    );
    final updatedProject = project.copyWith(
      beatMap: beatMap ?? project.beatMap,
      tracks: _upsertManualMediaTrack(
        tracks: tracksWithMarker,
        mediaEvent: mediaEvent,
        beatMap: beatMap ?? project.beatMap,
      ),
    );

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        selectedMarker: TimelineMarkerSelection(time: time, mediaId: item.id),
        nextQueuedMediaIndex: currentState.nextQueuedMediaIndex + 1,
      ),
    );
  }

  void selectImageMarker({required Duration time, String? mediaId}) {
    final currentState = _currentState;
    _emit(
      currentState.copyWith(
        selectedMarker: TimelineMarkerSelection(time: time, mediaId: mediaId),
      ),
    );
  }

  void clearImageMarkerSelection() {
    final currentState = _currentState;
    if (!currentState.hasSelectedMarker) {
      return;
    }

    _emit(currentState.copyWith(clearSelectedMarker: true));
  }

  void deleteSelectedImageMarker() {
    final currentState = _currentState;
    final selection = currentState.selectedMarker;
    final project = currentState.project;
    if (selection == null || project == null) {
      return;
    }

    final updatedProject = project.copyWith(
      tracks: _deleteSelectedMarker(
        tracks: project.tracks,
        selection: selection,
      ),
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        clearSelectedMarker: true,
      ),
    );
  }

  void reset() {
    state = const AsyncData(TimelineState.initial());
  }

  TimelineState get _currentState {
    return state.asData?.value ?? const TimelineState.initial();
  }

  void _emit(TimelineState nextState) {
    state = AsyncData(nextState);
  }

  Map<String, Object?> _serialize(ProjectTimeline project) {
    return ref.read(projectSerializerProvider).serialize(project);
  }

  List<TimelineTrack> _upsertMarkerTrack({
    required List<TimelineTrack> tracks,
    required BeatEvent markerEvent,
  }) {
    final markerTrack =
        _trackById(tracks, 'track-markers') ??
        const TimelineTrack(id: 'track-markers', name: 'Markers', events: []);

    final updatedMarkerTrack = markerTrack.copyWith(
      events: _sortedEvents([
        for (final event in markerTrack.events)
          if (event.time != markerEvent.time) event,
        markerEvent,
      ]),
    );

    return List.unmodifiable([
      updatedMarkerTrack,
      for (final track in tracks)
        if (track.id != 'track-markers') track,
    ]);
  }

  List<TimelineTrack> _deleteSelectedMarker({
    required List<TimelineTrack> tracks,
    required TimelineMarkerSelection selection,
  }) {
    return List.unmodifiable([
      for (final track in tracks)
        track.copyWith(
          events: track.id == 'track-markers' || track.id == 'track-media'
              ? List.unmodifiable([
                  for (final event in track.events)
                    if (event.time != selection.time) event,
                ])
              : track.events,
        ),
    ]);
  }

  List<TimelineTrack> _upsertManualMediaTrack({
    required List<TimelineTrack> tracks,
    required BeatEvent mediaEvent,
    required BeatMap beatMap,
  }) {
    final mediaTrack =
        _trackById(tracks, 'track-media') ??
        const TimelineTrack(id: 'track-media', name: 'Images', events: []);
    final sortedEvents = _sortedEvents([
      for (final event in mediaTrack.events)
        if (event.time != mediaEvent.time) event,
      mediaEvent,
    ]);
    final normalizedEvents = <BeatEvent>[];

    for (var index = 0; index < sortedEvents.length; index++) {
      final event = sortedEvents[index];
      final payload = event.payload;
      if (payload is! MediaTrackClipPayload) {
        normalizedEvents.add(event);
        continue;
      }

      final nextStart = index + 1 < sortedEvents.length
          ? sortedEvents[index + 1].time
          : event.time + _manualClipSpan(beatMap);
      normalizedEvents.add(
        BeatEvent(
          time: event.time,
          type: event.type,
          payload: payload.copyWith(start: event.time, end: nextStart),
        ),
      );
    }

    final updatedMediaTrack = mediaTrack.copyWith(
      events: List.unmodifiable(normalizedEvents),
    );

    return List.unmodifiable([
      for (final track in tracks)
        if (track.id != 'track-media') track,
      updatedMediaTrack,
    ]);
  }

  List<BeatEvent> _resolveMarkerEvents({
    required ProjectTimeline? currentProject,
    required List<BeatEvent> fallbackEvents,
  }) {
    final currentMarkers = _trackById(
      currentProject?.tracks ?? const [],
      'track-markers',
    )?.events;
    if (currentProject != null) {
      return _sortedEvents(currentMarkers ?? const []);
    }
    return _sortedEvents(fallbackEvents);
  }

  int _markerCount(List<TimelineTrack> tracks) {
    return _trackById(tracks, 'track-markers')?.events.length ?? 0;
  }

  TimelineTrack? _trackById(List<TimelineTrack> tracks, String id) {
    for (final track in tracks) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  List<BeatEvent> _sortedEvents(List<BeatEvent> events) {
    final sortedEvents = [...events]..sort((a, b) => a.time.compareTo(b.time));
    return List.unmodifiable(sortedEvents);
  }

  BeatMap _manualBeatMap(Duration? audioDuration) {
    return BeatMap(
      beats: const [],
      bpm: 0,
      averageBeatInterval: _manualAverageInterval(audioDuration),
    );
  }

  Duration _manualAverageInterval(Duration? audioDuration) {
    if (audioDuration != null && audioDuration > Duration.zero) {
      final segment = audioDuration ~/ 12;
      if (segment > Duration.zero) {
        return segment;
      }
    }
    return const Duration(seconds: 2);
  }

  Duration _manualClipSpan(BeatMap beatMap) {
    final templateDuration =
        _currentState.selectedTemplate.defaultSlideDuration;
    if (templateDuration > Duration.zero) {
      return templateDuration;
    }
    if (beatMap.averageBeatInterval > const Duration(seconds: 2)) {
      return beatMap.averageBeatInterval;
    }
    return const Duration(seconds: 2);
  }
}
