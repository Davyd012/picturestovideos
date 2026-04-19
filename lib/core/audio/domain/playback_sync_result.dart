import 'package:picturestovideos/core/audio/domain/beat.dart';

class PlaybackSyncResult {
  const PlaybackSyncResult({
    required this.triggeredBeats,
    required this.nextBeatIndex,
  });

  final List<Beat> triggeredBeats;
  final int nextBeatIndex;
}
