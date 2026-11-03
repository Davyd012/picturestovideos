import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/audio_marker_preset_use_case.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/timeline/application/build_project_timeline_use_case.dart';
import 'package:picturestovideos/core/timeline/application/edit_clip_boundary_use_case.dart';
import 'package:picturestovideos/core/timeline/application/move_timeline_clip_use_case.dart';
import 'package:picturestovideos/core/timeline/application/update_audio_mix_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/clip_id.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_marker_payload.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
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
  ProjectTimeline? _pacingUndoProject;
  ProjectTimeline? _pacingAppliedProject;
  ProjectTimeline? _bulkEditBefore;
  ProjectTimeline? _bulkEditAfter;
  bool _bulkEditPending = false;
  bool _undoFraming = false;
  bool _undoCaptionStyle = false;
  bool _undoCaptionText = false;
  bool _undoCaptionPosition = false;
  bool _undoCaptionTiming = false;
  bool _undoMotion = false;
  bool _undoTransition = false;
  ProjectTimeline? _markerUndoBefore;
  ProjectTimeline? _markerUndoAfter;
  bool _hasMarkerUndo = false;

  void bulkEditStarted({
    bool framing = false,
    bool captionStyle = false,
    bool captionText = false,
    bool captionPosition = false,
    bool captionTiming = false,
    bool motion = false,
    bool transition = false,
  }) {
    _bulkEditBefore = _currentState.project;
    _bulkEditAfter = null;
    _bulkEditPending = true;
    _undoFraming = framing;
    _undoCaptionStyle = captionStyle;
    _undoCaptionText = captionText;
    _undoCaptionPosition = captionPosition;
    _undoCaptionTiming = captionTiming;
    _undoMotion = motion;
    _undoTransition = transition;
  }

  void bulkEditFinished() {
    _bulkEditAfter = _currentState.project;
  }

  bool bulkEditUndone() {
    final before = _bulkEditBefore;
    final after = _bulkEditAfter;
    final current = _currentState;
    final project = current.project;
    if (!_bulkEditPending ||
        (before == null && project != null) ||
        (before != null &&
            (project == null || after == null || project.id != after.id))) {
      return false;
    }
    _bulkEditPending = false;
    _bulkEditBefore = null;
    _bulkEditAfter = null;
    if (before == null) return true;
    Map<String, MediaTrackClipPayload> clips(ProjectTimeline source) => {
      for (final track in source.tracks)
        if (track.id == 'track-media')
          for (final event in track.events)
            if (event.payload case final MediaTrackClipPayload clip)
              clip.clipId: clip,
    };
    final originals = clips(before);
    final applied = clips(after!);
    final updated = project!.copyWith(
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id != 'track-media')
            track
          else
            track.copyWith(
              events: List.unmodifiable([
                for (final event in track.events)
                  if (event.payload case final MediaTrackClipPayload clip)
                    BeatEvent(
                      time: event.time,
                      type: event.type,
                      payload: _undoBulkClip(
                        clip,
                        originals[clip.clipId],
                        applied[clip.clipId],
                      ),
                    )
                  else
                    event,
              ]),
            ),
      ]),
    );
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
    return true;
  }

  MediaTrackClipPayload _undoBulkClip(
    MediaTrackClipPayload current,
    MediaTrackClipPayload? before,
    MediaTrackClipPayload? after,
  ) {
    if (before == null ||
        after == null ||
        before.mediaId != current.mediaId ||
        after.mediaId != current.mediaId) {
      return current;
    }
    var result = current;
    if (_undoFraming &&
        current.imageFit == after.imageFit &&
        current.cropTransform == after.cropTransform) {
      result = result.copyWith(
        imageFit: before.imageFit,
        cropTransform: before.cropTransform,
      );
    }
    bool sameStyle(CaptionSettings a, CaptionSettings b) =>
        a.preset == b.preset &&
        a.sizeScale == b.sizeScale &&
        a.textColor == b.textColor &&
        a.backdrop == b.backdrop;
    if (_undoCaptionStyle &&
        sameStyle(current.captionSettings, after.captionSettings)) {
      result = result.copyWith(
        captionSettings: current.captionSettings.copyStyleFrom(
          before.captionSettings,
        ),
      );
    }
    if (_undoCaptionText &&
        current.caption == after.caption &&
        current.captionSupportingLine == after.captionSupportingLine) {
      result = result.copyWith(
        caption: before.caption,
        captionSupportingLine: before.captionSupportingLine,
      );
    }
    if (_undoCaptionPosition &&
        current.captionSettings.placement == after.captionSettings.placement) {
      result = result.copyWith(
        captionSettings: result.captionSettings.copyWith(
          placement: before.captionSettings.placement,
          clearPlacement: before.captionSettings.placement == null,
        ),
      );
    }
    if (_undoCaptionTiming &&
        current.captionSettings.entrance == after.captionSettings.entrance &&
        current.captionSettings.startFraction ==
            after.captionSettings.startFraction &&
        current.captionSettings.endFraction ==
            after.captionSettings.endFraction) {
      result = result.copyWith(
        captionSettings: result.captionSettings.copyWith(
          entrance: before.captionSettings.entrance,
          startFraction: before.captionSettings.startFraction,
          endFraction: before.captionSettings.endFraction,
        ),
      );
    }
    if (_undoMotion &&
        current.motionOverride == after.motionOverride &&
        current.motionIntensity == after.motionIntensity &&
        current.useStyleMotionIntensity == after.useStyleMotionIntensity) {
      result = result.copyWith(
        motionOverride: before.motionOverride,
        clearMotionOverride: before.motionOverride == null,
        motionIntensity: before.motionIntensity,
        useStyleMotionIntensity: before.useStyleMotionIntensity,
      );
    }
    if (_undoTransition &&
        current.transitionOverride == after.transitionOverride &&
        current.transitionDuration == after.transitionDuration) {
      result = result.copyWith(
        transitionOverride: before.transitionOverride,
        clearTransitionOverride: before.transitionOverride == null,
        transitionDuration: before.transitionDuration,
      );
    }
    return result;
  }

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
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
    String? audioSourcePath,
    Duration? audioDuration,
  }) async {
    _bulkEditPending = false;
    _pacingUndoProject = null;
    _pacingAppliedProject = null;
    final currentState = _currentState;
    final currentProject = currentState.project;
    final markerEvents = _resolveMarkerEvents(currentProject: currentProject);
    ref
        .read(appLoggerProvider)
        .info(
          _tag,
          'Building timeline from ${markerEvents.length} markers and ${selectedMedia.length} media items',
        );
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final builtProject = ref
          .read(buildProjectTimelineUseCaseProvider)
          .call(
            beatMap: beatMap,
            events: markerEvents,
            selectedMedia: selectedMedia,
            selectedImageFits: selectedImageFits,
            selectedCropTransforms: selectedCropTransforms,
            template: currentState.selectedTemplate,
            previousProject: currentProject,
            audioDuration: audioDuration,
          );
      final project = audioSourcePath == null
          ? builtProject
          : builtProject.copyWith(audioSourcePath: audioSourcePath);
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

  Future<void> applyPacingSuggestion({
    required BeatMap beatMap,
    required List<BeatEvent> events,
    required List<LibraryMediaItem> selectedMedia,
    required Map<String, VideoTemplateImageFit> selectedImageFits,
    required Duration? audioDuration,
  }) async {
    final before = _currentState.project;
    await buildProjectTimeline(
      beatMap: beatMap,
      events: events,
      selectedMedia: selectedMedia,
      selectedImageFits: selectedImageFits,
      audioDuration: audioDuration,
    );
    final applied = _currentState.project;
    if (before != null && applied != null) {
      _pacingUndoProject = before;
      _pacingAppliedProject = applied;
    }
  }

  void undoPacingSuggestion() {
    final previous = _pacingUndoProject;
    if (previous == null ||
        !identical(_currentState.project, _pacingAppliedProject)) {
      return;
    }
    _pacingUndoProject = null;
    _pacingAppliedProject = null;
    _emit(
      _currentState.copyWith(
        project: previous,
        serializedProject: _serialize(previous),
      ),
    );
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
    final project = _currentState.project;
    final offset = project?.audioMix.start ?? Duration.zero;
    final markers = [
      for (final marker in _markerEventsFromProject(project))
        BeatEvent(
          time: marker.time + offset,
          type: marker.type,
          payload: marker.payload is TimelineMarkerPayload
              ? (marker.payload as TimelineMarkerPayload).name
              : marker.payload,
        ),
    ];
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
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
  }) {
    // Queue edits never move clips implicitly. Applying markers is explicit.
  }

  int applyMarkersToImages({
    required List<LibraryMediaItem> selectedMedia,
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
  }) {
    final current = _currentState;
    final project = current.project;
    if (project == null || selectedMedia.isEmpty) return 0;
    final markers = _markerEventsFromProject(project);
    if (markers.isEmpty) return 0;
    final mediaTrack =
        _trackById(project.tracks, 'track-media') ??
        const TimelineTrack(id: 'track-media', name: 'Images', events: []);
    final oldClips = [
      for (final event in mediaTrack.events)
        if (event.payload is MediaTrackClipPayload)
          event.payload as MediaTrackClipPayload,
    ];
    final available = [...oldClips];
    final assignments = <({BeatEvent marker, MediaTrackClipPayload clip})>[];
    final count = selectedMedia.length < markers.length
        ? selectedMedia.length
        : markers.length;
    for (var index = 0; index < count; index++) {
      final item = selectedMedia[index];
      final oldIndex = available.indexWhere((clip) => clip.mediaId == item.id);
      final existing = oldIndex < 0 ? null : available.removeAt(oldIndex);
      final clip =
          existing ??
          MediaTrackClipPayload(
            clipId: newClipId(),
            mediaId: item.id,
            title: item.title,
            tagline: item.tagline,
            start: markers[index].time,
            end:
                markers[index].time +
                current.selectedTemplate.defaultSlideDuration,
            sourcePath: item.sourcePath,
            imageFit:
                selectedImageFits[item.id] ?? current.selectedTemplate.imageFit,
            cropTransform:
                selectedCropTransforms[item.id] ?? ImageCropTransform.centered,
          );
      assignments.add((marker: markers[index], clip: clip));
    }
    if (assignments.isEmpty) return 0;
    final lastMarkerEnd =
        assignments.last.marker.time +
        current.selectedTemplate.defaultSlideDuration;
    final existingEnd = project.videoDuration;
    final projectEnd = existingEnd == null || existingEnd < lastMarkerEnd
        ? lastMarkerEnd
        : existingEnd;
    final newMediaEvents = <BeatEvent>[];
    for (var index = 0; index < assignments.length; index++) {
      final assignment = assignments[index];
      final start = assignment.marker.time;
      final end = index + 1 < assignments.length
          ? assignments[index + 1].marker.time
          : projectEnd;
      if (end <= start) continue;
      newMediaEvents.add(
        BeatEvent(
          time: start,
          type: 'image',
          payload: assignment.clip.copyWith(start: start, end: end),
        ),
      );
    }
    final assignedClipIds = assignments
        .map((value) => value.clip.clipId)
        .toSet();
    newMediaEvents.addAll([
      for (final event in mediaTrack.events)
        if (event.payload is! MediaTrackClipPayload ||
            !assignedClipIds.contains(
              (event.payload as MediaTrackClipPayload).clipId,
            ))
          event,
    ]);
    final linkByTime = <Duration, String>{
      for (var index = 0; index < assignments.length; index++)
        assignments[index].marker.time: assignments[index].clip.clipId,
    };
    final markerTrack = _trackById(project.tracks, 'track-markers')!;
    final updatedMarkers = [
      for (final event in markerTrack.events)
        () {
          final payload = event.payload is TimelineMarkerPayload
              ? event.payload as TimelineMarkerPayload
              : TimelineMarkerPayload(id: newClipId());
          final clipId = linkByTime[event.time];
          return BeatEvent(
            time: event.time,
            type: event.type,
            payload: clipId == null
                ? payload.copyWith(unlink: true)
                : payload.copyWith(linkedClipId: clipId),
          );
        }(),
    ];
    final updated = project.copyWith(
      hasManualEdits: true,
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id == 'track-markers')
            track.copyWith(events: _sortedEvents(updatedMarkers))
          else if (track.id == 'track-media')
            track.copyWith(events: _sortedEvents(newMediaEvents))
          else
            track,
        if (_trackById(project.tracks, 'track-media') == null)
          mediaTrack.copyWith(events: _sortedEvents(newMediaEvents)),
      ]),
    );
    _rememberMarkerUndo(project, updated);
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
        nextQueuedMediaIndex: count,
      ),
    );
    return count;
  }

  /// Appends queued media that is not already represented on the timeline.
  /// Existing clips and their edits are left untouched.
  int appendQueuedMedia({
    required List<LibraryMediaItem> items,
    required Map<String, VideoTemplateImageFit> imageFits,
    required Map<String, ImageCropTransform> cropTransforms,
  }) {
    if (items.isEmpty) return 0;
    final current = _currentState;
    final project =
        current.project ??
        ProjectTimeline(
          id: newClipId(),
          name: 'Picture To Videos Project',
          beatMap: _manualBeatMap(null),
          tracks: const [],
          template: current.selectedTemplate,
        );
    final track =
        _trackById(project.tracks, 'track-media') ??
        const TimelineTrack(id: 'track-media', name: 'Images', events: []);
    final existing = track.events
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .toList();
    final ids = existing.map((clip) => clip.mediaId).toSet();
    final events = [...track.events];
    var start = existing.fold<Duration>(
      Duration.zero,
      (end, clip) => clip.end > end ? clip.end : end,
    );
    var added = 0;
    for (final item in items) {
      if (!ids.add(item.id)) continue;
      final end = start + current.selectedTemplate.defaultSlideDuration;
      final clip = MediaTrackClipPayload(
        clipId: newClipId(),
        mediaId: item.id,
        title: item.title,
        tagline: item.tagline,
        start: start,
        end: end,
        sourcePath: item.sourcePath,
        imageFit: imageFits[item.id] ?? current.selectedTemplate.imageFit,
        cropTransform: cropTransforms[item.id] ?? ImageCropTransform.centered,
      );
      events.add(BeatEvent(time: start, type: 'image', payload: clip));
      start = end;
      added++;
    }
    if (added == 0) return 0;
    final updated = project.copyWith(
      hasManualEdits: true,
      tracks: List.unmodifiable([
        for (final entry in project.tracks)
          if (entry.id != 'track-media') entry,
        track.copyWith(events: List.unmodifiable(events)),
      ]),
    );
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
    return added;
  }

  void pacingSelected(SequencePacing pacing) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null || project.pacing == pacing) return;
    final updated = project.copyWith(pacing: pacing);
    _emit(
      currentState.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void audioMixChanged(AudioMix mix) {
    final current = _currentState;
    final project = current.project;
    if (project == null || project.audioMix == mix) return;
    final updated = const UpdateAudioMixUseCase().call(project, mix);
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
        clearSelectedMarker: true,
      ),
    );
  }

  void clipTimingChanged({
    required String clipId,
    Duration? duration,
    required bool snap,
  }) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) return;
    var updated = project.copyWith(snapToMarkers: snap);
    if (duration != null) {
      updated = const EditClipBoundaryUseCase().call(
        project: updated,
        clipId: clipId,
        duration: duration,
        snap: snap,
      );
      updated = _syncLinkedMarkerTimes(updated);
      if (!identical(updated, project)) _rememberMarkerUndo(project, updated);
    }
    _emit(
      currentState.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
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
    final existingMarker = _markerEventsFromProject(project)
        .where((event) => event.time == time)
        .firstOrNull;
    if (existingMarker != null) {
      final payload = existingMarker.payload;
      _emit(
        currentState.copyWith(
          selectedMarker: TimelineMarkerSelection(
            time: time,
            markerId: payload is TimelineMarkerPayload ? payload.id : null,
          ),
        ),
      );
      return;
    }
    final markerEvent = BeatEvent(
      time: time,
      type: 'marker',
      payload: TimelineMarkerPayload(id: newClipId()),
    );
    final updatedProject = project.copyWith(
      beatMap: beatMap,
      tracks: _upsertMarkerTrack(
        tracks: project.tracks,
        markerEvent: markerEvent,
      ),
    );
    _rememberMarkerUndo(project, updatedProject);

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        selectedMarker: TimelineMarkerSelection(
          time: time,
          markerId: (markerEvent.payload as TimelineMarkerPayload).id,
        ),
      ),
    );
  }

  void addManualImagePointAt({
    required Duration time,
    required BeatMap? beatMap,
    required List<LibraryMediaItem> selectedMedia,
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
    required Duration? audioDuration,
  }) {
    if (selectedMedia.isEmpty) {
      return;
    }

    final currentState = _currentState;
    final project =
        currentState.project ??
        ProjectTimeline(
          id: newClipId(),
          name: 'Picture To Videos Project',
          beatMap: beatMap ?? _manualBeatMap(audioDuration),
          tracks: const [
            TimelineTrack(id: 'track-markers', name: 'Markers', events: []),
          ],
          template: currentState.selectedTemplate,
        );
    final mediaIndex = currentState.nextQueuedMediaIndex % selectedMedia.length;
    final item = selectedMedia[mediaIndex];
    final existingMarker = _markerEventsFromProject(project)
        .where((event) => event.time == time)
        .firstOrNull;
    final existingMarkerPayload = existingMarker?.payload;
    if (existingMarkerPayload is TimelineMarkerPayload &&
        existingMarkerPayload.linkedClipId != null) {
      return;
    }
    final mediaEvent = BeatEvent(
      time: time,
      type: 'image',
      payload: MediaTrackClipPayload(
        clipId: newClipId(),
        mediaId: item.id,
        title: item.title,
        tagline: item.tagline,
        start: time,
        end: time + _manualClipSpan(project.beatMap),
        sourcePath: item.sourcePath,
        imageFit:
            selectedImageFits[item.id] ??
            currentState.selectedTemplate.imageFit,
        cropTransform:
            selectedCropTransforms[item.id] ?? ImageCropTransform.centered,
      ),
    );
    final markerEvent = BeatEvent(
      time: time,
      type: 'marker',
      payload: TimelineMarkerPayload(
        id: existingMarkerPayload is TimelineMarkerPayload
            ? existingMarkerPayload.id
            : newClipId(),
        linkedClipId: (mediaEvent.payload as MediaTrackClipPayload).clipId,
        name: item.title,
      ),
    );
    final tracksWithMarker = _upsertMarkerTrack(
      tracks: project.tracks,
      markerEvent: markerEvent,
    );
    final updatedProject = project.copyWith(
      beatMap: beatMap ?? project.beatMap,
      hasManualEdits: true,
      tracks: _upsertManualMediaTrack(
        tracks: tracksWithMarker,
        mediaEvent: mediaEvent,
        beatMap: beatMap ?? project.beatMap,
      ),
    );
    _rememberMarkerUndo(project, updatedProject);

    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        selectedMarker: TimelineMarkerSelection(
          time: time,
          mediaId: item.id,
          markerId: (markerEvent.payload as TimelineMarkerPayload).id,
        ),
        nextQueuedMediaIndex: currentState.nextQueuedMediaIndex + 1,
      ),
    );
  }

  void selectImageMarker({required Duration time, String? mediaId}) {
    final currentState = _currentState;
    final marker = _markerEventsFromProject(currentState.project)
        .where((event) => event.time == time)
        .firstOrNull;
    final payload = marker?.payload;
    _emit(
      currentState.copyWith(
        selectedMarker: TimelineMarkerSelection(
          time: time,
          mediaId: mediaId,
          markerId: payload is TimelineMarkerPayload ? payload.id : null,
        ),
      ),
    );
  }

  /// Moves a marker and, when linked, its image start as one project edit.
  void moveSelectedImageMarker(Duration time) {
    final current = _currentState;
    final project = current.project;
    final selection = current.selectedMarker;
    if (project == null || selection == null || time.isNegative) return;
    if (time > const Duration(hours: 24) ||
        project.videoDuration != null && time > project.videoDuration!) {
      return;
    }
    final oldTime = selection.time;
    if (time == oldTime) return;
    final markerTrack = _trackById(project.tracks, 'track-markers');
    if (markerTrack == null) return;
    final marker = markerTrack.events
        .where(
          (event) => selection.markerId != null
              ? event.payload is TimelineMarkerPayload &&
                    (event.payload as TimelineMarkerPayload).id ==
                        selection.markerId
              : event.time == oldTime,
        )
        .firstOrNull;
    if (marker == null) return;
    final markerPayload = marker.payload;
    final linkedClipId = markerPayload is TimelineMarkerPayload
        ? markerPayload.linkedClipId
        : null;
    final mediaTrack = _trackById(project.tracks, 'track-media');
    final mediaEvents = [...?mediaTrack?.events];
    if (markerTrack.events.any(
      (event) => event != marker && event.time == time,
    )) {
      return;
    }
    if (linkedClipId != null) {
      final index = mediaEvents.indexWhere(
        (event) =>
            event.payload is MediaTrackClipPayload &&
            (event.payload as MediaTrackClipPayload).clipId == linkedClipId,
      );
      if (index < 0) return;
      final clip = mediaEvents[index].payload as MediaTrackClipPayload;
      final newEnd = clip.end;
      if (newEnd - time < EditClipBoundaryUseCase.minimumClipDuration) return;
      if (index + 1 < mediaEvents.length &&
          mediaEvents[index + 1].payload is MediaTrackClipPayload &&
          (mediaEvents[index + 1].payload as MediaTrackClipPayload).start <
              newEnd) {
        return;
      }
      for (var otherIndex = 0; otherIndex < mediaEvents.length; otherIndex++) {
        if (otherIndex == index || otherIndex == index - 1) continue;
        final otherPayload = mediaEvents[otherIndex].payload;
        if (otherPayload is MediaTrackClipPayload &&
            time < otherPayload.end &&
            newEnd > otherPayload.start) {
          return;
        }
      }
      mediaEvents[index] = BeatEvent(
        time: time,
        type: mediaEvents[index].type,
        payload: clip.copyWith(start: time, end: newEnd),
      );
      if (index > 0 &&
          mediaEvents[index - 1].payload is MediaTrackClipPayload) {
        final previousEvent = mediaEvents[index - 1];
        final previous = previousEvent.payload as MediaTrackClipPayload;
        if (previous.end == clip.start &&
            time - previous.start >=
                EditClipBoundaryUseCase.minimumClipDuration) {
          mediaEvents[index - 1] = BeatEvent(
            time: previousEvent.time,
            type: previousEvent.type,
            payload: previous.copyWith(end: time),
          );
        } else if (previous.end == clip.start) {
          return;
        }
      }
    }
    final markerEvents = [
      for (final event in markerTrack.events)
        if (event == marker)
          BeatEvent(time: time, type: event.type, payload: event.payload)
        else
          event,
    ];
    final updated = project.copyWith(
      hasManualEdits: true,
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id == 'track-markers')
            track.copyWith(events: _sortedEvents(markerEvents))
          else if (track.id == 'track-media' && linkedClipId != null)
            track.copyWith(events: _sortedEvents(mediaEvents))
          else
            track,
      ]),
    );
    _rememberMarkerUndo(project, updated);
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
        selectedMarker: TimelineMarkerSelection(
          time: time,
          markerId: markerPayload is TimelineMarkerPayload
              ? markerPayload.id
              : null,
        ),
      ),
    );
  }

  /// Changes text for a single timeline occurrence, even when media is reused.
  void captionChanged({
    required String clipId,
    required String caption,
    required String supportingLine,
  }) {
    _editClip(
      clipId,
      (clip) => clip.copyWith(
        caption: caption,
        captionSupportingLine: supportingLine,
      ),
    );
  }

  void captionSettingsChanged({
    required String clipId,
    required CaptionSettings settings,
  }) {
    _editClip(clipId, (clip) => clip.copyWith(captionSettings: settings));
  }

  void captionTextAppliedToAll(String caption, String supportingLine) =>
      _applyCaptionToAll(
        (clip) => clip.copyWith(
          caption: caption,
          captionSupportingLine: supportingLine,
        ),
      );

  void captionPositionAppliedToAll(CaptionSettings settings) =>
      _applyCaptionToAll(
        (clip) => clip.copyWith(
          captionSettings: clip.captionSettings.copyWith(
            placement: settings.placement,
            clearPlacement: settings.placement == null,
          ),
        ),
      );

  void captionTimingAppliedToAll(CaptionSettings settings) =>
      _applyCaptionToAll(
        (clip) => clip.copyWith(
          captionSettings: clip.captionSettings.copyWith(
            entrance: settings.entrance,
            startFraction: settings.startFraction,
            endFraction: settings.endFraction,
          ),
        ),
      );

  void captionStyleAppliedToAll(CaptionSettings style) => _applyCaptionToAll(
    (clip) => clip.copyWith(
      captionSettings: clip.captionSettings.copyStyleFrom(style),
    ),
  );

  void _applyCaptionToAll(
    MediaTrackClipPayload Function(MediaTrackClipPayload) apply,
  ) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) return;
    final updatedTracks = [
      for (final track in project.tracks)
        if (track.id == 'track-media')
          track.copyWith(
            events: List.unmodifiable([
              for (final event in track.events)
                if (event.payload is MediaTrackClipPayload)
                  BeatEvent(
                    time: event.time,
                    type: event.type,
                    payload: apply(event.payload as MediaTrackClipPayload),
                  )
                else
                  event,
            ]),
          )
        else
          track,
    ];
    final updated = project.copyWith(
      tracks: List.unmodifiable(updatedTracks),
      hasManualEdits: true,
    );
    _emit(
      currentState.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void clipImageFitChanged({
    required String clipId,
    required VideoTemplateImageFit imageFit,
  }) {
    _editClip(clipId, (clip) => clip.copyWith(imageFit: imageFit));
  }

  bool clipMoved({required String clipId, required int position}) {
    final current = _currentState;
    final project = current.project;
    if (project == null) return false;
    final moved = const MoveTimelineClipUseCase().call(
      project,
      clipId,
      position,
    );
    if (identical(moved, project)) return false;
    final updated = _syncLinkedMarkerTimes(moved);
    if (!identical(updated, project)) _rememberMarkerUndo(project, updated);
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
    return true;
  }

  void clipRemoved({required String clipId}) {
    if (clipId.isEmpty) return;
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) return;

    final mediaTrack = _trackById(project.tracks, 'track-media');
    if (mediaTrack == null ||
        !mediaTrack.events.any(
          (event) =>
              event.payload is MediaTrackClipPayload &&
              (event.payload as MediaTrackClipPayload).clipId == clipId,
        )) {
      return;
    }
    final updatedTracks = [
      for (final track in project.tracks)
        if (track.id == 'track-markers')
          track.copyWith(
            events: List.unmodifiable([
              for (final event in track.events)
                if (event.payload is TimelineMarkerPayload &&
                    (event.payload as TimelineMarkerPayload).linkedClipId ==
                        clipId)
                  BeatEvent(
                    time: event.time,
                    type: event.type,
                    payload: (event.payload as TimelineMarkerPayload).copyWith(
                      unlink: true,
                    ),
                  )
                else
                  event,
            ]),
          )
        else if (track.id != 'track-media')
          track
        else
          track.copyWith(
            events: List.unmodifiable(
              track.events.where(
                (event) =>
                    event.payload is! MediaTrackClipPayload ||
                    (event.payload as MediaTrackClipPayload).clipId != clipId,
              ),
            ),
          ),
    ];

    final updated = _syncLinkedMarkerTimes(
      project.copyWith(
        tracks: List.unmodifiable(updatedTracks),
        hasManualEdits: true,
      ),
    );
    _emit(
      currentState.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void clipMotionChanged({
    required String clipId,
    ClipMotionPreset? preset,
    ClipMotionIntensity? intensity,
  }) {
    _editClip(
      clipId,
      (clip) => clip.copyWith(
        motionOverride: preset,
        clearMotionOverride: preset == null,
        motionIntensity: intensity,
        useStyleMotionIntensity: intensity == null,
      ),
    );
  }

  void clipMotionAppliedToAll({
    ClipMotionPreset? preset,
    ClipMotionIntensity? intensity,
  }) {
    final current = _currentState;
    final project = current.project;
    if (project == null) return;
    final updated = project.copyWith(
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id == 'track-media')
            track.copyWith(
              events: List.unmodifiable([
                for (final event in track.events)
                  if (event.payload is MediaTrackClipPayload)
                    BeatEvent(
                      time: event.time,
                      type: event.type,
                      payload: (event.payload as MediaTrackClipPayload)
                          .copyWith(
                            motionOverride: preset,
                            clearMotionOverride: preset == null,
                            motionIntensity: intensity,
                            useStyleMotionIntensity: intensity == null,
                          ),
                    )
                  else
                    event,
              ]),
            )
          else
            track,
      ]),
      hasManualEdits: true,
    );
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void clipTransitionChanged({
    required String clipId,
    ClipTransitionType? type,
    required Duration duration,
  }) {
    _editClip(
      clipId,
      (clip) => clip.copyWith(
        transitionOverride: type,
        clearTransitionOverride: type == null,
        transitionDuration: Duration(
          milliseconds: duration.inMilliseconds.clamp(100, 2000),
        ),
      ),
    );
  }

  void clipTransitionAppliedToAll({
    ClipTransitionType? type,
    required Duration duration,
  }) {
    final current = _currentState;
    final project = current.project;
    if (project == null) return;
    final tracks = [
      for (final track in project.tracks)
        if (track.id != 'track-media')
          track
        else
          (() {
            final last = track.events.lastIndexWhere(
              (event) => event.payload is MediaTrackClipPayload,
            );
            return track.copyWith(
              events: List.unmodifiable([
                for (var i = 0; i < track.events.length; i++)
                  if (i != last &&
                      track.events[i].payload is MediaTrackClipPayload)
                    BeatEvent(
                      time: track.events[i].time,
                      type: track.events[i].type,
                      payload:
                          (track.events[i].payload as MediaTrackClipPayload)
                              .copyWith(
                                transitionOverride: type,
                                clearTransitionOverride: type == null,
                                transitionDuration: Duration(
                                  milliseconds: duration.inMilliseconds.clamp(
                                    100,
                                    2000,
                                  ),
                                ),
                              ),
                    )
                  else
                    track.events[i],
              ]),
            );
          })(),
    ];
    final updated = project.copyWith(
      tracks: List.unmodifiable(tracks),
      hasManualEdits: true,
    );
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void clipCropChanged({
    required String clipId,
    required ImageCropTransform transform,
  }) {
    _editClip(clipId, (clip) => clip.copyWith(cropTransform: transform));
  }

  void clipFramingAppliedToAll({
    required VideoTemplateImageFit imageFit,
    required ImageCropTransform crop,
  }) {
    final current = _currentState;
    final project = current.project;
    if (project == null) return;
    final updated = project.copyWith(
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id == 'track-media')
            track.copyWith(
              events: List.unmodifiable([
                for (final event in track.events)
                  if (event.payload is MediaTrackClipPayload)
                    BeatEvent(
                      time: event.time,
                      type: event.type,
                      payload: (event.payload as MediaTrackClipPayload)
                          .copyWith(imageFit: imageFit, cropTransform: crop),
                    )
                  else
                    event,
              ]),
            )
          else
            track,
      ]),
      hasManualEdits: true,
    );
    _emit(
      current.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
      ),
    );
  }

  void _editClip(
    String clipId,
    MediaTrackClipPayload Function(MediaTrackClipPayload) edit,
  ) {
    if (clipId.isEmpty) return;
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) return;
    var found = false;
    final tracks = [
      for (final track in project.tracks)
        if (track.id != 'track-media')
          track
        else
          track.copyWith(
            events: List.unmodifiable([
              for (final event in track.events)
                if (event.payload is MediaTrackClipPayload &&
                    (event.payload as MediaTrackClipPayload).clipId == clipId)
                  BeatEvent(
                    time: event.time,
                    type: event.type,
                    payload: edit(event.payload as MediaTrackClipPayload),
                  )
                else
                  event,
            ]),
          ),
    ];
    for (final track in project.tracks) {
      if (track.id == 'track-media' &&
          track.events.any(
            (event) =>
                event.payload is MediaTrackClipPayload &&
                (event.payload as MediaTrackClipPayload).clipId == clipId,
          )) {
        found = true;
        break;
      }
    }
    if (!found) return;
    final updated = project.copyWith(
      tracks: List.unmodifiable(tracks),
      hasManualEdits: true,
    );
    _emit(
      currentState.copyWith(
        project: updated,
        serializedProject: _serialize(updated),
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
      hasManualEdits: true,
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
      ),
    );
  }

  void updateAllMediaImageFits(VideoTemplateImageFit imageFit) {
    final currentState = _currentState;
    final project = currentState.project;
    if (project == null) {
      return;
    }
    final updatedTracks = [
      for (final track in project.tracks)
        track.id == 'track-media'
            ? track.copyWith(
                events: List.unmodifiable([
                  for (final event in track.events)
                    event.payload is MediaTrackClipPayload
                        ? BeatEvent(
                            time: event.time,
                            type: event.type,
                            payload: (event.payload as MediaTrackClipPayload)
                                .copyWith(imageFit: imageFit),
                          )
                        : event,
                ]),
              )
            : track,
    ];
    final updatedProject = project.copyWith(
      tracks: List.unmodifiable(updatedTracks),
      hasManualEdits: true,
    );
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
      ),
    );
  }

  void updateMediaCropTransform({
    required String mediaId,
    required ImageCropTransform transform,
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
                    event.payload is MediaTrackClipPayload &&
                            (event.payload as MediaTrackClipPayload).mediaId ==
                                mediaId
                        ? BeatEvent(
                            time: event.time,
                            type: event.type,
                            payload: (event.payload as MediaTrackClipPayload)
                                .copyWith(cropTransform: transform),
                          )
                        : event,
                ]),
              )
            : track,
    ];
    for (final track in updatedTracks) {
      if (track.id == 'track-media') {
        didUpdate = track.events.any(
          (event) =>
              event.payload is MediaTrackClipPayload &&
              (event.payload as MediaTrackClipPayload).mediaId == mediaId,
        );
      }
    }
    if (!didUpdate) {
      return;
    }
    final updatedProject = project.copyWith(
      tracks: List.unmodifiable(updatedTracks),
      hasManualEdits: true,
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

  ProjectTimeline _syncLinkedMarkerTimes(ProjectTimeline project) {
    final starts = <String, Duration>{};
    for (final track in project.tracks) {
      if (track.id != 'track-media') continue;
      for (final event in track.events) {
        final clip = event.payload;
        if (clip is MediaTrackClipPayload) starts[clip.clipId] = clip.start;
      }
    }
    var changed = false;
    final tracks = [
      for (final track in project.tracks)
        if (track.id != 'track-markers')
          track
        else
          track.copyWith(
            events: List.unmodifiable([
              for (final event in track.events)
                _syncMarkerEvent(event, starts, () => changed = true),
            ]),
          ),
    ];
    return changed
        ? project.copyWith(tracks: List.unmodifiable(tracks))
        : project;
  }

  BeatEvent _syncMarkerEvent(
    BeatEvent event,
    Map<String, Duration> starts,
    void Function() onChanged,
  ) {
    final marker = event.payload;
    if (marker is! TimelineMarkerPayload || marker.linkedClipId == null) {
      return event;
    }
    final start = starts[marker.linkedClipId];
    if (start == null || start == event.time) return event;
    onChanged();
    return BeatEvent(time: start, type: event.type, payload: marker);
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
    _rememberMarkerUndo(project, updatedProject);
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
    _rememberMarkerUndo(project, updatedProject);
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
    _rememberMarkerUndo(project, updatedProject);
    _emit(
      currentState.copyWith(
        project: updatedProject,
        serializedProject: _serialize(updatedProject),
        clearSelectedMarker: true,
      ),
    );
  }

  void reset() {
    _bulkEditPending = false;
    state = const AsyncData(TimelineState.initial());
  }

  void projectOpened(ProjectTimeline project) {
    _bulkEditPending = false;
    _emit(
      TimelineState(
        project: project,
        serializedProject: _serialize(project),
        selectedMarker: null,
        nextQueuedMediaIndex: 0,
        selectedTemplate: project.template,
        timelineScale: 1,
      ),
    );
  }

  void projectMediaRelinked(ProjectTimeline project) {
    _emit(
      _currentState.copyWith(
        project: project,
        serializedProject: _serialize(project),
      ),
    );
  }

  TimelineState get _currentState {
    return state.asData?.value ?? const TimelineState.initial();
  }

  void _emit(TimelineState nextState) {
    state = AsyncData(nextState);
  }

  void _rememberMarkerUndo(ProjectTimeline before, ProjectTimeline after) {
    if (!_hasMarkerUndo || !identical(before, _markerUndoAfter)) {
      _markerUndoBefore = before;
    }
    _markerUndoAfter = after;
    _hasMarkerUndo = true;
  }

  void markerEditGestureStarted() {
    _hasMarkerUndo = false;
    _markerUndoBefore = null;
    _markerUndoAfter = null;
  }

  bool undoMarkerEdit() {
    final current = _currentState;
    final before = _markerUndoBefore;
    if (!_hasMarkerUndo ||
        before == null ||
        !identical(current.project, _markerUndoAfter)) {
      return false;
    }
    _hasMarkerUndo = false;
    _markerUndoBefore = null;
    _markerUndoAfter = null;
    final oldSelection = current.selectedMarker;
    final restoredMarker = oldSelection == null
        ? null
        : _markerEventsFromProject(before).where((event) {
            final payload = event.payload;
            return oldSelection.markerId != null &&
                    payload is TimelineMarkerPayload
                ? payload.id == oldSelection.markerId
                : event.time == oldSelection.time;
          }).firstOrNull;
    final restoredPayload = restoredMarker?.payload;
    _emit(
      current.copyWith(
        project: before,
        serializedProject: _serialize(before),
        selectedMarker: restoredMarker == null
            ? null
            : TimelineMarkerSelection(
                time: restoredMarker.time,
                markerId: restoredPayload is TimelineMarkerPayload
                    ? restoredPayload.id
                    : null,
              ),
        clearSelectedMarker: restoredMarker == null,
      ),
    );
    return true;
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
    if (selection.markerId != null) {
      return List.unmodifiable([
        for (final track in tracks)
          track.copyWith(
            events: track.id == 'track-markers'
                ? List.unmodifiable([
                    for (final event in track.events)
                      if (event.payload is! TimelineMarkerPayload ||
                          (event.payload as TimelineMarkerPayload).id !=
                              selection.markerId)
                        event,
                  ])
                : track.events,
          ),
      ]);
    }
    return _deleteMarkerAtTime(tracks: tracks, time: selection.time);
  }

  List<TimelineTrack> _deleteMarkerAtTime({
    required List<TimelineTrack> tracks,
    required Duration time,
  }) {
    return List.unmodifiable([
      for (final track in tracks)
        track.copyWith(
          events: track.id == 'track-markers'
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
        track.id == 'track-markers' ? track.copyWith(events: const []) : track,
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
      if (marker.time.isNegative) continue;
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
  }) {
    final currentMarkers = _markerEventsFromProject(currentProject);
    if (currentProject != null) {
      return currentMarkers;
    }
    return const [];
  }

  List<BeatEvent> _markerEventsFromProject(ProjectTimeline? project) {
    return _sortedEvents(
      _trackById(project?.tracks ?? const [], 'track-markers')?.events ??
          const [],
    );
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
