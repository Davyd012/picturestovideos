import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/timeline/application/build_project_timeline_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
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
    final currentProject = _currentState.project;
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
      );
    });
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
            .call(beatMap: beatMap, events: fallbackMarkerEvents);
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
}
