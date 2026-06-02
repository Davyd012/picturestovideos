import 'dart:typed_data';

import 'package:picturestovideos/core/audio/domain/audio_analysis_config.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_detection_config.dart';

class DecodeWavAudioRequest {
  const DecodeWavAudioRequest({
    required this.bytes,
  });

  final Uint8List bytes;
}

class DecodeWavAudioResult {
  const DecodeWavAudioResult({
    required this.audioData,
  });

  final AudioData audioData;
}

class AnalyzeAudioFramesRequest {
  const AnalyzeAudioFramesRequest({
    required this.audioData,
    required this.config,
  });

  final AudioData audioData;
  final AudioAnalysisConfig config;
}

class AnalyzeAudioFramesResult {
  const AnalyzeAudioFramesResult({
    required this.frames,
  });

  final List<AudioFrame> frames;
}

class DetectBeatsRequest {
  const DetectBeatsRequest({
    required this.frames,
    required this.config,
  });

  final List<AudioFrame> frames;
  final BeatDetectionConfig config;
}

class DetectBeatsResult {
  const DetectBeatsResult({
    required this.beats,
  });

  final List<Beat> beats;
}
