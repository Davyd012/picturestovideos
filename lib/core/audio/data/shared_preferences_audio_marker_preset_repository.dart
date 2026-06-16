import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/audio_marker_preset_repository.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

final audioMarkerPresetRepositoryProvider =
    Provider<AudioMarkerPresetRepository>(
      (ref) => const SharedPreferencesAudioMarkerPresetRepository(),
    );

class SharedPreferencesAudioMarkerPresetRepository
    implements AudioMarkerPresetRepository {
  const SharedPreferencesAudioMarkerPresetRepository();

  static const _collectionStorageKey = 'audio_marker_preset_entries';
  static const _legacyStorageKey = 'audio_marker_preset_entry';

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_collectionStorageKey);
    await preferences.remove(_legacyStorageKey);
  }

  @override
  Future<AudioMarkerPreset?> load({required String audioSignature}) async {
    final presets = await loadAll();
    for (final preset in presets) {
      if (preset.audioSignature == audioSignature) {
        return preset;
      }
    }
    return null;
  }

  @override
  Future<List<AudioMarkerPreset>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final collectionJson = preferences.getString(_collectionStorageKey);
    if (collectionJson != null) {
      final decoded = jsonDecode(collectionJson) as Map<String, Object?>;
      return _deserializeCollection(decoded);
    }

    final legacyJson = preferences.getString(_legacyStorageKey);
    if (legacyJson == null) {
      return const [];
    }

    final decoded = jsonDecode(legacyJson) as Map<String, Object?>;
    return [_deserialize(decoded)];
  }

  @override
  Future<void> save(AudioMarkerPreset preset) async {
    final preferences = await SharedPreferences.getInstance();
    final currentPresets = await loadAll();
    final nextPresets = [
      preset,
      for (final currentPreset in currentPresets)
        if (currentPreset.audioSignature != preset.audioSignature)
          currentPreset,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await preferences.setString(
      _collectionStorageKey,
      jsonEncode(_serializeCollection(nextPresets)),
    );
  }

  Map<String, Object?> _serializeCollection(List<AudioMarkerPreset> presets) {
    return {
      'version': 1,
      'presets': [for (final preset in presets) _serialize(preset)],
    };
  }

  Map<String, Object?> _serialize(AudioMarkerPreset preset) {
    return {
      'version': preset.version,
      'audioSignature': preset.audioSignature,
      'sourceName': preset.sourceName,
      'sourcePath': preset.sourcePath,
      'sourceExtension': preset.sourceExtension,
      'byteLength': preset.byteLength,
      'durationMs': preset.duration.inMilliseconds,
      'updatedAt': preset.updatedAt.toIso8601String(),
      'markers': [
        for (final marker in preset.markers)
          {
            'timeMs': marker.time.inMilliseconds,
            'type': marker.type,
            'payload': marker.payload?.toString(),
          },
      ],
    };
  }

  List<AudioMarkerPreset> _deserializeCollection(Map<String, Object?> json) {
    final presetsJson = json['presets'];
    if (presetsJson is! List<Object?>) {
      return const [];
    }

    final presets = [
      for (final presetJson in presetsJson)
        if (presetJson is Map<String, Object?>) _deserialize(presetJson),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(presets);
  }

  AudioMarkerPreset _deserialize(Map<String, Object?> json) {
    return AudioMarkerPreset(
      version: json['version']! as int,
      audioSignature: json['audioSignature']! as String,
      sourceName: json['sourceName']! as String,
      sourcePath: json['sourcePath'] as String?,
      sourceExtension: json['sourceExtension'] as String? ?? '',
      byteLength: json['byteLength'] as int? ?? 0,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      markers: [
        for (final markerJson in json['markers']! as List<Object?>)
          _deserializeMarker(markerJson! as Map<String, Object?>),
      ],
    );
  }

  BeatEvent _deserializeMarker(Map<String, Object?> json) {
    return BeatEvent(
      time: Duration(milliseconds: json['timeMs']! as int),
      type: json['type']! as String,
      payload: json['payload'],
    );
  }
}
