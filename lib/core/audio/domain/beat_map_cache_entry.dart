import 'package:picturestovideos/core/audio/domain/beat_map.dart';

class BeatMapCacheEntry {
  const BeatMapCacheEntry({
    required this.version,
    required this.audioSignature,
    required this.beatMap,
  });

  final int version;
  final String audioSignature;
  final BeatMap beatMap;
}
