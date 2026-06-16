import 'package:picturestovideos/core/audio/domain/beat_map_cache_entry.dart';

abstract interface class BeatMapCacheRepository {
  Future<BeatMapCacheEntry?> load({required String audioSignature});

  Future<void> save(BeatMapCacheEntry entry);

  Future<void> clear();
}
