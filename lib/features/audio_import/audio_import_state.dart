import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_source.dart';

enum AudioImportPipelineStatus { idle, running, success, failure }

enum AudioImportPipelineStage {
  importFile,
  decodeAudio,
  analyzeAudio,
  detectBeats,
  buildBeatMap,
  loadEvents,
  preparePlayback,
  buildTimeline,
}

class AudioImportState {
  const AudioImportState({
    required this.source,
    required this.audioData,
    required this.status,
    required this.activeStage,
    required this.completedStages,
    required this.errorStage,
    required this.errorMessage,
    required this.warningMessage,
  });

  const AudioImportState.initial()
      : source = null,
        audioData = null,
        status = AudioImportPipelineStatus.idle,
        activeStage = null,
        completedStages = const [],
        errorStage = null,
        errorMessage = null,
        warningMessage = null;

  final AudioSource? source;
  final AudioData? audioData;
  final AudioImportPipelineStatus status;
  final AudioImportPipelineStage? activeStage;
  final List<AudioImportPipelineStage> completedStages;
  final AudioImportPipelineStage? errorStage;
  final String? errorMessage;
  final String? warningMessage;

  bool get hasSelectedFile => source != null;
  bool get hasAudio => source != null && audioData != null;
  bool get isRunning => status == AudioImportPipelineStatus.running;
  bool get isSuccess => status == AudioImportPipelineStatus.success;
  bool get isFailure => status == AudioImportPipelineStatus.failure;
  bool get hasWarning => warningMessage != null && warningMessage!.isNotEmpty;

  bool get canOpenEditor =>
      hasAudio && completedStages.contains(AudioImportPipelineStage.buildTimeline);

  double get progressValue {
    if (isSuccess) {
      return 1;
    }

    final totalStages = AudioImportPipelineStage.values.length;
    final completedCount = completedStages.length;
    final inFlight = isRunning && activeStage != null ? 0.5 : 0.0;
    return ((completedCount + inFlight) / totalStages)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  String get progressLabel {
    if (isFailure && errorStage != null) {
      return 'Pipeline stopped during ${titleForStage(errorStage!)}';
    }
    if (isSuccess) {
      return hasWarning
          ? 'Ready for editor handoff with limited playback'
          : 'Ready for editor handoff';
    }
    if (isRunning && activeStage != null) {
      return detailForStage(activeStage!);
    }
    if (hasSelectedFile) {
      return 'Audio selected and waiting to process';
    }
    return 'Waiting for the first audio file';
  }

  String get importDetail => source?.fileName ?? 'No audio imported';

  bool isStageComplete(AudioImportPipelineStage stage) {
    return completedStages.contains(stage);
  }

  bool isStageRunning(AudioImportPipelineStage stage) {
    return isRunning && activeStage == stage;
  }

  bool isStageFailed(AudioImportPipelineStage stage) {
    return isFailure && errorStage == stage;
  }

  String titleForStage(AudioImportPipelineStage stage) {
    return switch (stage) {
      AudioImportPipelineStage.importFile => 'Import',
      AudioImportPipelineStage.decodeAudio => 'Decode',
      AudioImportPipelineStage.analyzeAudio => 'Analysis',
      AudioImportPipelineStage.detectBeats => 'Beat detection',
      AudioImportPipelineStage.buildBeatMap => 'Beat map',
      AudioImportPipelineStage.loadEvents => 'Events',
      AudioImportPipelineStage.preparePlayback => 'Playback',
      AudioImportPipelineStage.buildTimeline => 'Timeline',
    };
  }

  String detailForStage(AudioImportPipelineStage stage) {
    if (isStageFailed(stage) && errorMessage != null) {
      return errorMessage!;
    }

    return switch (stage) {
      AudioImportPipelineStage.importFile =>
        hasSelectedFile ? importDetail : 'Choose a WAV file to begin.',
      AudioImportPipelineStage.decodeAudio => hasAudio
          ? 'Decoded ${audioData!.samples.length} samples.'
          : 'Decoding WAV samples in the background.',
      AudioImportPipelineStage.analyzeAudio => isStageComplete(stage)
          ? 'Energy frames generated.'
          : 'Analyzing frame energy in the background.',
      AudioImportPipelineStage.detectBeats => isStageComplete(stage)
          ? 'Beat candidates detected.'
          : 'Scanning for beat candidates in the background.',
      AudioImportPipelineStage.buildBeatMap => isStageComplete(stage)
          ? 'Beat map is ready.'
          : 'Building beat map from detected beats.',
      AudioImportPipelineStage.loadEvents => isStageComplete(stage)
          ? 'Marker events loaded.'
          : 'Preparing marker events from the beat map.',
      AudioImportPipelineStage.preparePlayback => isStageComplete(stage)
          ? 'Playback is prepared.'
          : 'Preparing audio playback state.',
      AudioImportPipelineStage.buildTimeline => isStageComplete(stage)
          ? 'Timeline is ready for the editor.'
          : 'Building the project timeline.',
    };
  }

  AudioImportState copyWith({
    AudioSource? source,
    AudioData? audioData,
    AudioImportPipelineStatus? status,
    AudioImportPipelineStage? activeStage,
    List<AudioImportPipelineStage>? completedStages,
    AudioImportPipelineStage? errorStage,
    String? errorMessage,
    String? warningMessage,
    bool clearActiveStage = false,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return AudioImportState(
      source: source ?? this.source,
      audioData: audioData ?? this.audioData,
      status: status ?? this.status,
      activeStage: clearActiveStage ? null : activeStage ?? this.activeStage,
      completedStages: completedStages ?? this.completedStages,
      errorStage: clearError ? null : errorStage ?? this.errorStage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      warningMessage: clearWarning
          ? null
          : warningMessage ?? this.warningMessage,
    );
  }
}
