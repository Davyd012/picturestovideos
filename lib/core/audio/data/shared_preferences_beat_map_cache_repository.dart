import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/beat_map_cache_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/beat_map_cache_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

final beatMapCacheRepositoryProvider = Provider<BeatMapCacheRepository>(
  (ref) => const SharedPreferencesBeatMapCacheRepository(),
);

class SharedPreferencesBeatMapCacheRepository
    implements BeatMapCacheRepository {
  const SharedPreferencesBeatMapCacheRepository();

  static const _storageKey = 'beat_map_cache_entry';

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @override
  Future<BeatMapCacheEntry?> load({required String audioSignature}) async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = preferences.getString(_storageKey);
    if (jsonString == null) {
      return null;
    }

    final decoded = jsonDecode(jsonString) as Map<String, Object?>;
    final entry = _deserialize(decoded);
    if (entry.audioSignature != audioSignature) {
      return null;
    }

    return entry;
  }

  @override
  Future<void> save(BeatMapCacheEntry entry) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_serialize(entry)));
  }

  Map<String, Object?> _serialize(BeatMapCacheEntry entry) {
    return {
      'version': entry.version,
      'audioSignature': entry.audioSignature,
      'bpm': entry.beatMap.bpm,
      'averageBeatIntervalMs': entry.beatMap.averageBeatInterval.inMilliseconds,
      'beats': [
        for (final beat in entry.beatMap.beats)
          {'timeMs': beat.time.inMilliseconds, 'strength': beat.strength},
      ],
    };
  }

  BeatMapCacheEntry _deserialize(Map<String, Object?> json) {
    return BeatMapCacheEntry(
      version: json['version']! as int,
      audioSignature: json['audioSignature']! as String,
      beatMap: BeatMap(
        beats: [
          for (final beatJson in json['beats']! as List<Object?>)
            _deserializeBeat(beatJson! as Map<String, Object?>),
        ],
        bpm: (json['bpm']! as num).toDouble(),
        averageBeatInterval: Duration(
          milliseconds: json['averageBeatIntervalMs']! as int,
        ),
      ),
    );
  }

  Beat _deserializeBeat(Map<String, Object?> json) {
    return Beat(
      time: Duration(milliseconds: json['timeMs']! as int),
      strength: (json['strength']! as num).toDouble(),
    );
  }
}
