import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/audio_marker_preset_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
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
  static const _minTimelineScale = 0.75;
  static const _maxTimelineScale = 3.0;
  static const _currentPointDeleteTolerance = Duration(milliseconds: 250);

  @override
  Future<TimelineState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing timeline state');
    return const TimelineState.initial();
  }

  Future<void> buildProjectTimeline({
    required BeatMap beatMap,
    required List<BeatEvent> events,
    List<LibraryMediaItem> selectedMedia = const [],
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
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
            selectedImageFits: selectedImageFits,
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
        timelineScale: currentState.timelineScale,
      );
    });
  }

  void timelineScaleChanged(double scale) {
    final currentState = _currentState;
    final clampedScale = scale
        .clamp(_minTimelineScale, _maxTimelineScale)
        .toDouble();
    _emit(currentState.copyWith(timelineScale: clampedScale));
  }

  void templateSelected(VideoTemplate template) {
    final currentState = _currentState;
    final currentProject = currentState.project;
    final updatedTemplate = template.copyWith(
      aspectRatio: currentState.selectedTemplate.aspectRatio,
    );
    final updatedProject = currentProject?.copyWith(template: updatedTemplate);

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: updatedProject == null
            ? currentState.serializedProject
            : _serialize(updatedProject),
        selectedTemplate: updatedTemplate,
      ),
    );
  }

  void aspectRatioSelected(VideoTemplateAspectRatio aspectRatio) {
    final currentState = _currentState;
    final updatedTemplate = currentState.selectedTemplate.copyWith(
      aspectRatio: aspectRatio,
    );
    final updatedProject = currentState.project?.copyWith(
      template: updatedTemplate,
    );

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: updatedProject == null
            ? currentState.serializedProject
            : _serialize(updatedProject),
        selectedTemplate: updatedTemplate,
      ),
    );
  }

  Future<int> saveMarkerPreset({
    required AudioData audioData,
    required String sourceName,
    String? sourcePath,
    String sourceExtension = '',
    int byteLength = 0,
  }) async {
    final markers = _markerEventsFromProject(_currentState.project);
    if (markers.isEmpty) {
      return 0;
    }

    await ref
        .read(audioMarkerPresetUseCaseProvider)
        .savePreset(
          audioData: audioData,
          sourceName: sourceName,
          sourcePath: sourcePath,
          sourceExtension: sourceExtension,
          byteLength: byteLength,
          markers: markers,
        );
    return markers.length;
  }

  void syncSelectedMediaToMarkers({
    required List<LibraryMediaItem> selectedMedia,
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
  }) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) {
      return;
    }

    final markers = _markerEventsFromProject(project);
    if (markers.isEmpty) {
      return;
    }

    final updatedProject = ref
        .read(buildProjectTimelineUseCaseProvider)
        .call(
          beatMap: project.beatMap,
          events: markers,
          selectedMedia: selectedMedia,
          selectedImageFits: selectedImageFits,
          template: currentState.selectedTemplate,
        );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        nextQueuedMediaIndex: 0,
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
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
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
        imageFit:
            selectedImageFits[item.id] ??
            currentState.selectedTemplate.imageFit,
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

  void updateMediaImageFit({
    required String mediaId,
    required VideoTemplateImageFit imageFit,
  }) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) {
      return;
    }

    var didUpdate = false;
    final updatedTracks = [
      for (final track in project.tracks)
        track.id == 'track-media'
            ? track.copyWith(
                events: List.unmodifiable([
                  for (final event in track.events)
                    _updateMediaEventImageFit(
                      event: event,
                      mediaId: mediaId,
                      imageFit: imageFit,
                      didUpdate: () => didUpdate = true,
                    ),
                ]),
              )
            : track,
    ];

    if (!didUpdate) {
      return;
    }

    final updatedProject = project.copyWith(
      tracks: List.unmodifiable(updatedTracks),
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
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

  void deleteImageMarkerAt(Duration time) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) {
      return;
    }

    final markerTime = _markerTimeNear(project: project, time: time);
    if (markerTime == null) {
      return;
    }

    final updatedProject = project.copyWith(
      tracks: _deleteMarkerAtTime(tracks: project.tracks, time: markerTime),
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        clearSelectedMarker: true,
      ),
    );
  }

  void clearImageMarkers() {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) {
      return;
    }

    final updatedProject = project.copyWith(
      tracks: _clearMarkerTracks(project.tracks),
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        nextQueuedMediaIndex: 0,
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
    return _deleteMarkerAtTime(tracks: tracks, time: selection.time);
  }

  List<TimelineTrack> _deleteMarkerAtTime({
    required List<TimelineTrack> tracks,
    required Duration time,
  }) {
    return List.unmodifiable([
      for (final track in tracks)
        track.copyWith(
          events: track.id == 'track-markers' || track.id == 'track-media'
              ? List.unmodifiable([
                  for (final event in track.events)
                    if (event.time != time) event,
                ])
              : track.events,
        ),
    ]);
  }

  List<TimelineTrack> _clearMarkerTracks(List<TimelineTrack> tracks) {
    return List.unmodifiable([
      for (final track in tracks)
        track.id == 'track-markers' || track.id == 'track-media'
            ? track.copyWith(events: const [])
            : track,
    ]);
  }

  Duration? _markerTimeNear({
    required ProjectTimeline project,
    required Duration time,
  }) {
    final markers = _markerEventsFromProject(project);
    Duration? closestTime;
    var closestDistance = _currentPointDeleteTolerance;

    for (final marker in markers) {
      final distance = _durationDistance(marker.time, time);
      if (distance <= closestDistance) {
        closestDistance = distance;
        closestTime = marker.time;
      }
    }

    return closestTime;
  }

  Duration _durationDistance(Duration first, Duration second) {
    final distance = first - second;
    return distance.isNegative ? -distance : distance;
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

  BeatEvent _updateMediaEventImageFit({
    required BeatEvent event,
    required String mediaId,
    required VideoTemplateImageFit imageFit,
    required void Function() didUpdate,
  }) {
    final payload = event.payload;
    if (payload is! MediaTrackClipPayload || payload.mediaId != mediaId) {
      return event;
    }

    didUpdate();
    return BeatEvent(
      time: event.time,
      type: event.type,
      payload: payload.copyWith(imageFit: imageFit),
    );
  }

  List<BeatEvent> _resolveMarkerEvents({
    required ProjectTimeline? currentProject,
    required List<BeatEvent> fallbackEvents,
  }) {
    final currentMarkers = _markerEventsFromProject(currentProject);
    if (currentProject != null) {
      return currentMarkers;
    }
    return _sortedEvents(fallbackEvents);
  }

  List<BeatEvent> _markerEventsFromProject(ProjectTimeline? project) {
    return _sortedEvents(
      _trackById(project?.tracks ?? const [], 'track-markers')?.events ??
          const [],
    );
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
