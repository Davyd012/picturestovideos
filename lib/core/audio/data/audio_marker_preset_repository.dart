import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';

abstract interface class AudioMarkerPresetRepository {
  Future<AudioMarkerPreset?> load({required String audioSignature});

  Future<List<AudioMarkerPreset>> loadAll();

  Future<void> save(AudioMarkerPreset preset);

  Future<void> clear();
}
