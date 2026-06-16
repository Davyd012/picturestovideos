import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/application/audio_cache_signature_builder.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/data/shared_preferences_audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

final audioMarkerPresetUseCaseProvider = Provider<AudioMarkerPresetUseCase>(
  (ref) => AudioMarkerPresetUseCase(
    repository: ref.watch(audioMarkerPresetRepositoryProvider),
    signatureBuilder: ref.watch(audioCacheSignatureBuilderProvider),
  ),
);

class AudioMarkerPresetUseCase {
  const AudioMarkerPresetUseCase({
    required AudioMarkerPresetRepository repository,
    required AudioCacheSignatureBuilder signatureBuilder,
  }) : this._(repository, signatureBuilder);

  const AudioMarkerPresetUseCase._(this._repository, this._signatureBuilder);

  static const version = 1;

  final AudioMarkerPresetRepository _repository;
  final AudioCacheSignatureBuilder _signatureBuilder;

  Future<AudioMarkerPreset?> loadPreset(AudioData audioData) async {
    final preset = await _repository.load(
      audioSignature: _signatureBuilder.build(audioData),
    );
    if (preset == null || preset.version != version) {
      return null;
    }

    return preset;
  }

  Future<void> savePreset({
    required AudioData audioData,
    required String sourceName,
    required List<BeatEvent> markers,
    String? sourcePath,
    String sourceExtension = '',
    int byteLength = 0,
  }) {
    return _repository.save(
      AudioMarkerPreset(
        version: version,
        audioSignature: _signatureBuilder.build(audioData),
        sourceName: sourceName,
        sourcePath: sourcePath,
        sourceExtension: sourceExtension,
        byteLength: byteLength,
        duration: audioData.duration,
        markers: List.unmodifiable(markers),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
