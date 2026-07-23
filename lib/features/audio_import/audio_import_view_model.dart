import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/audio_marker_preset_use_case.dart';
import 'package:picturestovideos/core/audio/application/decode_wav_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/import_audio_use_case.dart';
import 'package:picturestovideos/core/audio/application/prepare_audio_for_analysis_use_case.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/audio/domain/audio_processing_task.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/selected_audio_file.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/features/audio_analysis/audio_analysis_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/beat_detection/beat_detection_view_model.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

final audioImportViewModelProvider =
    AsyncNotifierProvider<AudioImportViewModel, AudioImportState>(
      AudioImportViewModel.new,
    );

class AudioImportViewModel extends AsyncNotifier<AudioImportState> {
  static const _tag = 'AudioImportViewModel';
  int _pipelineSession = 0;

  @override
  Future<AudioImportState> build() async {
    ref.read(appLoggerProvider).info(_tag, 'Initializing import state');
    return const AudioImportState.initial();
  }

  Future<void> pickAudioFile() async {
    final logger = ref.read(appLoggerProvider);
    final previousState = state.value ?? const AudioImportState.initial();
    if (previousState.isBusy) {
      return;
    }

    logger.info(_tag, 'Pick audio requested');
    state = AsyncData(
      previousState.copyWith(
        status: AudioImportPipelineStatus.pickingFile,
        clearActiveStage: true,
        clearError: true,
        clearWarning: true,
      ),
    );
    final selectedFile = await ref.read(importAudioUseCaseProvider).call();
    await _runImportPipeline(selectedFile, previousState: previousState);
  }

  Future<void> importAudioFromPath(String path) async {
    final logger = ref.read(appLoggerProvider);
    final previousState = state.value ?? const AudioImportState.initial();
    if (previousState.isBusy) {
      return;
    }

    logger.info(_tag, 'Manual audio import requested for $path');
    state = AsyncData(
      previousState.copyWith(
        status: AudioImportPipelineStatus.pickingFile,
        clearActiveStage: true,
        clearError: true,
        clearWarning: true,
      ),
    );
    final selectedFile = await ref
        .read(importAudioUseCaseProvider)
        .fromPath(path);
    await _runImportPipeline(selectedFile, previousState: previousState);
  }

  Future<void> selectSongOnly() async {
    final logger = ref.read(appLoggerProvider);
    final previousState = state.value ?? const AudioImportState.initial();
    if (previousState.isBusy) {
      return;
    }

    logger.info(_tag, 'Song-only selection requested');
    state = AsyncData(
      previousState.copyWith(
        status: AudioImportPipelineStatus.pickingFile,
        clearActiveStage: true,
        clearError: true,
        clearWarning: true,
        isSongOnly: true,
      ),
    );
    final selectedFile = await ref
        .read(importAudioUseCaseProvider)
        .selectSong();
    await _runSongOnlyPipeline(selectedFile, previousState: previousState);
  }

  Future<void> selectSongOnlyFromPath(String path) async {
    final logger = ref.read(appLoggerProvider);
    final previousState = state.value ?? const AudioImportState.initial();
    if (previousState.isBusy) {
      return;
    }

    logger.info(_tag, 'Manual song-only selection requested for $path');
    state = AsyncData(
      previousState.copyWith(
        status: AudioImportPipelineStatus.pickingFile,
        clearActiveStage: true,
        clearError: true,
        clearWarning: true,
        isSongOnly: true,
      ),
    );
    final selectedFile = await ref
        .read(importAudioUseCaseProvider)
        .selectSongFromPath(path);
    await _runSongOnlyPipeline(selectedFile, previousState: previousState);
  }

  Future<void> stopImport() async {
    _pipelineSession++;
    ref.read(appLoggerProvider).warning(_tag, 'Import stopped by user');
    await _resetDownstreamState();
    state = const AsyncData(AudioImportState.initial());
  }

  Future<void> importAnotherFile() async {
    await stopImport();
  }

  Future<void> _runImportPipeline(
    SelectedAudioFile? selectedFile, {
    required AudioImportState previousState,
  }) async {
    final session = ++_pipelineSession;
    if (selectedFile == null) {
      ref
          .read(appLoggerProvider)
          .warning(_tag, 'Audio import canceled or returned no file');
      if (_isCurrentSession(session)) {
        state = AsyncData(previousState);
      }
      return;
    }

    await _resetDownstreamState();

    var currentState = AudioImportState(
      source: selectedFile.source,
      audioData: null,
      status: AudioImportPipelineStatus.running,
      activeStage: AudioImportPipelineStage.decodeAudio,
      completedStages: const [AudioImportPipelineStage.importFile],
      errorStage: null,
      errorMessage: null,
      warningMessage: null,
      isSongOnly: false,
    );
    state = AsyncData(currentState);

    try {
      ref
          .read(appLoggerProvider)
          .info(_tag, 'Running automatic import pipeline');

      final analysisFile = await ref
          .read(prepareAudioForAnalysisUseCaseProvider)
          .call(selectedFile);
      if (!_isCurrentSession(session)) {
        return;
      }
      final audioData = await ref
          .read(decodeWavAudioUseCaseProvider)
          .call(request: DecodeWavAudioRequest(bytes: analysisFile.bytes));
      if (!_isCurrentSession(session)) {
        return;
      }
      currentState = _advanceState(
        currentState.copyWith(audioData: audioData),
        completedStage: AudioImportPipelineStage.decodeAudio,
        nextStage: AudioImportPipelineStage.analyzeAudio,
      );
      state = AsyncData(currentState);

      final markerPreset = await ref
          .read(audioMarkerPresetUseCaseProvider)
          .loadPreset(audioData);
      if (!_isCurrentSession(session)) {
        return;
      }
      if (markerPreset != null && markerPreset.markers.isNotEmpty) {
        await _completePipelineFromMarkerPreset(
          currentState: currentState,
          selectedFile: selectedFile,
          markerPreset: markerPreset,
          session: session,
        );
        return;
      }

      await ref
          .read(audioAnalysisViewModelProvider.notifier)
          .analyzeAudio(audioData);
      if (!_isCurrentSession(session)) {
        return;
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.analyzeAudio,
        nextStage: AudioImportPipelineStage.detectBeats,
      );
      state = AsyncData(currentState);

      final frames =
          ref.read(audioAnalysisViewModelProvider).asData?.value.frames ??
          const <AudioFrame>[];
      await ref
          .read(beatDetectionViewModelProvider.notifier)
          .detectBeats(frames);
      if (!_isCurrentSession(session)) {
        return;
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.detectBeats,
        nextStage: AudioImportPipelineStage.buildBeatMap,
      );
      state = AsyncData(currentState);

      final beats =
          ref.read(beatDetectionViewModelProvider).asData?.value.beats ??
          const <Beat>[];
      await ref.read(beatMapViewModelProvider.notifier).buildBeatMap(beats);
      if (!_isCurrentSession(session)) {
        return;
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.buildBeatMap,
        nextStage: AudioImportPipelineStage.loadEvents,
      );
      state = AsyncData(currentState);

      final beatMap = ref.read(beatMapViewModelProvider).asData?.value.beatMap;
      if (beatMap == null || beatMap.beats.isEmpty) {
        throw StateError('Beat map could not be built.');
      }

      await ref
          .read(eventSystemViewModelProvider.notifier)
          .loadMarkerEventsFromBeatMap(beatMap);
      if (!_isCurrentSession(session)) {
        return;
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.loadEvents,
        nextStage: AudioImportPipelineStage.preparePlayback,
      );
      state = AsyncData(currentState);

      try {
        await ref
            .read(playbackViewModelProvider.notifier)
            .preparePlayback(
              beatMap: beatMap,
              audioSourcePath: selectedFile.source.path,
            );
        if (!_isCurrentSession(session)) {
          return;
        }
      } catch (error, stackTrace) {
        ref
            .read(appLoggerProvider)
            .warning(
              _tag,
              'Playback preparation failed, continuing import pipeline: ${_playbackPreparationMessage(error)}',
            );
        ref.read(appLoggerProvider).debug(_tag, stackTrace.toString());
        currentState = currentState.copyWith(
          warningMessage: _playbackPreparationMessage(error),
        );
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.preparePlayback,
        nextStage: AudioImportPipelineStage.buildTimeline,
      );
      state = AsyncData(currentState);

      final events =
          ref.read(eventSystemViewModelProvider).asData?.value.events ??
          const <BeatEvent>[];
      await ref
          .read(timelineViewModelProvider.notifier)
          .buildProjectTimeline(
            beatMap: beatMap,
            events: events,
            selectedMedia: _selectedMedia,
            selectedImageFits: _selectedImageFits,
            selectedCropTransforms: _selectedCropTransforms,
          );
      if (!_isCurrentSession(session)) {
        return;
      }

      currentState =
          _advanceState(
            currentState,
            completedStage: AudioImportPipelineStage.buildTimeline,
          ).copyWith(
            status: AudioImportPipelineStatus.success,
            clearActiveStage: true,
          );
      state = AsyncData(currentState);
    } catch (error, stackTrace) {
      if (!_isCurrentSession(session)) {
        return;
      }
      ref
          .read(appLoggerProvider)
          .error(
            _tag,
            error,
            stackTrace,
            message: 'Automatic import pipeline failed',
          );
      state = AsyncData(
        currentState.copyWith(
          status: AudioImportPipelineStatus.failure,
          errorStage: currentState.activeStage,
          errorMessage: error.toString(),
          clearActiveStage: true,
        ),
      );
    }
  }

  Future<void> _runSongOnlyPipeline(
    SelectedAudioFile? selectedFile, {
    required AudioImportState previousState,
  }) async {
    final session = ++_pipelineSession;
    if (selectedFile == null) {
      ref
          .read(appLoggerProvider)
          .warning(_tag, 'Song selection canceled or returned no file');
      if (_isCurrentSession(session)) {
        state = AsyncData(previousState);
      }
      return;
    }

    await _resetDownstreamState();

    var currentState = AudioImportState(
      source: selectedFile.source,
      audioData: null,
      status: AudioImportPipelineStatus.running,
      activeStage: AudioImportPipelineStage.preparePlayback,
      completedStages: const [AudioImportPipelineStage.importFile],
      errorStage: null,
      errorMessage: null,
      warningMessage: null,
      isSongOnly: true,
    );
    state = AsyncData(currentState);

    try {
      const manualBeatMap = BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 2),
      );
      try {
        await ref
            .read(playbackViewModelProvider.notifier)
            .preparePlayback(
              beatMap: manualBeatMap,
              audioSourcePath: selectedFile.source.path,
            );
        if (!_isCurrentSession(session)) {
          return;
        }
      } catch (error, stackTrace) {
        ref
            .read(appLoggerProvider)
            .warning(
              _tag,
              'Playback preparation failed for song-only selection: ${_playbackPreparationMessage(error)}',
            );
        ref.read(appLoggerProvider).debug(_tag, stackTrace.toString());
        currentState = currentState.copyWith(
          warningMessage: _playbackPreparationMessage(error),
        );
      }
      currentState = _advanceState(
        currentState,
        completedStage: AudioImportPipelineStage.preparePlayback,
        nextStage: AudioImportPipelineStage.buildTimeline,
      );
      state = AsyncData(currentState);

      await ref
          .read(timelineViewModelProvider.notifier)
          .buildProjectTimeline(
            beatMap: manualBeatMap,
            events: const [],
            selectedMedia: _selectedMedia,
            selectedImageFits: _selectedImageFits,
            selectedCropTransforms: _selectedCropTransforms,
          );
      if (!_isCurrentSession(session)) {
        return;
      }

      currentState =
          _advanceState(
            currentState,
            completedStage: AudioImportPipelineStage.buildTimeline,
          ).copyWith(
            status: AudioImportPipelineStatus.success,
            clearActiveStage: true,
          );
      state = AsyncData(currentState);
    } catch (error, stackTrace) {
      if (!_isCurrentSession(session)) {
        return;
      }
      ref
          .read(appLoggerProvider)
          .error(
            _tag,
            error,
            stackTrace,
            message: 'Song-only import pipeline failed',
          );
      state = AsyncData(
        currentState.copyWith(
          status: AudioImportPipelineStatus.failure,
          errorStage: currentState.activeStage,
          errorMessage: error.toString(),
          clearActiveStage: true,
        ),
      );
    }
  }

  bool _isCurrentSession(int session) {
    return session == _pipelineSession;
  }

  List<LibraryMediaItem> get _selectedMedia {
    return ref.read(editorMediaSelectionViewModelProvider).selectedMedia;
  }

  Map<String, VideoTemplateImageFit> get _selectedImageFits {
    return ref.read(editorMediaSelectionViewModelProvider).selectedImageFits;
  }

  Map<String, ImageCropTransform> get _selectedCropTransforms {
    return ref
        .read(editorMediaSelectionViewModelProvider)
        .selectedCropTransforms;
  }

  Future<void> _completePipelineFromMarkerPreset({
    required AudioImportState currentState,
    required SelectedAudioFile selectedFile,
    required AudioMarkerPreset markerPreset,
    required int session,
  }) async {
    var nextState = currentState.copyWith(
      activeStage: AudioImportPipelineStage.loadEvents,
    );
    state = AsyncData(nextState);

    final beatMap = markerPreset.toBeatMap();
    ref
        .read(eventSystemViewModelProvider.notifier)
        .loadMarkerEvents(markerPreset.markers);
    if (!_isCurrentSession(session)) {
      return;
    }
    nextState = _advanceState(
      nextState,
      completedStage: AudioImportPipelineStage.loadEvents,
      nextStage: AudioImportPipelineStage.preparePlayback,
    );
    state = AsyncData(nextState);

    try {
      await ref
          .read(playbackViewModelProvider.notifier)
          .preparePlayback(
            beatMap: beatMap,
            audioSourcePath: selectedFile.source.path,
          );
      if (!_isCurrentSession(session)) {
        return;
      }
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            _tag,
            'Playback preparation failed for marker preset: ${_playbackPreparationMessage(error)}',
          );
      ref.read(appLoggerProvider).debug(_tag, stackTrace.toString());
      nextState = nextState.copyWith(
        warningMessage: _playbackPreparationMessage(error),
      );
    }
    nextState = _advanceState(
      nextState,
      completedStage: AudioImportPipelineStage.preparePlayback,
      nextStage: AudioImportPipelineStage.buildTimeline,
    );
    state = AsyncData(nextState);

    final events =
        ref.read(eventSystemViewModelProvider).asData?.value.events ??
        const <BeatEvent>[];
    await ref
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: beatMap,
          events: events,
          selectedMedia: _selectedMedia,
          selectedImageFits: _selectedImageFits,
          selectedCropTransforms: _selectedCropTransforms,
        );
    if (!_isCurrentSession(session)) {
      return;
    }

    nextState =
        _advanceState(
          nextState,
          completedStage: AudioImportPipelineStage.buildTimeline,
        ).copyWith(
          status: AudioImportPipelineStatus.success,
          clearActiveStage: true,
        );
    state = AsyncData(nextState);
  }

  Future<void> _resetDownstreamState() async {
    ref.read(audioAnalysisViewModelProvider.notifier).reset();
    ref.read(beatDetectionViewModelProvider.notifier).reset();
    ref.read(beatMapViewModelProvider.notifier).reset();
    ref.read(eventSystemViewModelProvider.notifier).reset();
    await ref.read(playbackViewModelProvider.notifier).reset();
    ref.read(timelineViewModelProvider.notifier).reset();
  }

  AudioImportState _advanceState(
    AudioImportState currentState, {
    required AudioImportPipelineStage completedStage,
    AudioImportPipelineStage? nextStage,
  }) {
    final completedStages = [
      ...currentState.completedStages,
      if (!currentState.completedStages.contains(completedStage))
        completedStage,
    ];

    return currentState.copyWith(
      status: AudioImportPipelineStatus.running,
      activeStage: nextStage,
      completedStages: List.unmodifiable(completedStages),
      clearError: true,
      clearWarning: false,
    );
  }

  String _playbackPreparationMessage(Object error) {
    if (error is TimeoutException) {
      return 'Audio imported successfully, but playback preparation timed out. You can still open the editor and build the timeline.';
    }
    return 'Audio imported successfully, but playback could not be prepared automatically. You can still open the editor and build the timeline.';
  }
}
