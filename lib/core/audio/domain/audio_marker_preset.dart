import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

class AudioMarkerPreset {
  const AudioMarkerPreset({
    required this.version,
    required this.audioSignature,
    required this.sourceName,
    required this.markers,
    required this.updatedAt,
    this.sourcePath,
    this.sourceExtension = '',
    this.byteLength = 0,
    this.duration = Duration.zero,
  });

  final int version;
  final String audioSignature;
  final String sourceName;
  final String? sourcePath;
  final String sourceExtension;
  final int byteLength;
  final Duration duration;
  final List<BeatEvent> markers;
  final DateTime updatedAt;

  int get markerCount => markers.length;

  BeatMap toBeatMap() {
    final sortedMarkers = [...markers]
      ..sort((a, b) => a.time.compareTo(b.time));
    final averageInterval = _averageInterval(sortedMarkers);

    return BeatMap(
      beats: List.unmodifiable([
        for (final marker in sortedMarkers)
          Beat(time: marker.time, strength: 1),
      ]),
      bpm: _bpm(averageInterval),
      averageBeatInterval: averageInterval,
    );
  }

  Duration _averageInterval(List<BeatEvent> sortedMarkers) {
    if (sortedMarkers.length < 2) {
      return const Duration(seconds: 2);
    }

    var totalMs = 0;
    for (var index = 1; index < sortedMarkers.length; index++) {
      totalMs +=
          sortedMarkers[index].time.inMilliseconds -
          sortedMarkers[index - 1].time.inMilliseconds;
    }

    return Duration(milliseconds: totalMs ~/ (sortedMarkers.length - 1));
  }

  double _bpm(Duration averageInterval) {
    if (averageInterval <= Duration.zero) {
      return 0;
    }

    return 60000 / averageInterval.inMilliseconds;
  }
}
