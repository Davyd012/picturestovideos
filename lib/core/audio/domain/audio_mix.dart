import 'dart:math' as math;

/// Source times are absolute; the video begins at [start]. Null end uses the
/// available source duration. Fades are measured in video time.
class AudioMix {
  const AudioMix({
    this.start = Duration.zero,
    this.end,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
  });
  final Duration start;
  final Duration? end;
  final Duration fadeIn;
  final Duration fadeOut;

  @override
  bool operator ==(Object other) =>
      other is AudioMix &&
      start == other.start &&
      end == other.end &&
      fadeIn == other.fadeIn &&
      fadeOut == other.fadeOut;

  @override
  int get hashCode => Object.hash(start, end, fadeIn, fadeOut);

  AudioMix copyWith({
    Duration? start,
    Duration? end,
    bool clearEnd = false,
    Duration? fadeIn,
    Duration? fadeOut,
  }) => AudioMix(
    start: start ?? this.start,
    end: clearEnd ? null : end ?? this.end,
    fadeIn: fadeIn ?? this.fadeIn,
    fadeOut: fadeOut ?? this.fadeOut,
  );

  Map<String, Object?> toJson() => {
    'startMs': start.inMilliseconds,
    'endMs': end?.inMilliseconds,
    'fadeInMs': fadeIn.inMilliseconds,
    'fadeOutMs': fadeOut.inMilliseconds,
  };

  factory AudioMix.fromJson(Object? value) {
    if (value is! Map) return const AudioMix();
    final start = math.max(0, (value['startMs'] as int?) ?? 0);
    final end = value['endMs'] as int?;
    return AudioMix(
      start: Duration(milliseconds: start),
      end: end != null && end > start ? Duration(milliseconds: end) : null,
      fadeIn: Duration(
        milliseconds: math.max(0, (value['fadeInMs'] as int?) ?? 0),
      ),
      fadeOut: Duration(
        milliseconds: math.max(0, (value['fadeOutMs'] as int?) ?? 0),
      ),
    );
  }

  Duration effectiveDuration({
    Duration? sourceDuration,
    required Duration videoDuration,
  }) {
    final sourceEnd = end == null
        ? sourceDuration
        : sourceDuration == null || end! < sourceDuration
        ? end
        : sourceDuration;
    final available = sourceEnd == null ? videoDuration : sourceEnd - start;
    if (available <= Duration.zero || videoDuration <= Duration.zero) {
      return Duration.zero;
    }
    return available < videoDuration ? available : videoDuration;
  }

  double volumeAt(
    Duration position, {
    Duration? sourceDuration,
    required Duration videoDuration,
  }) {
    final length = effectiveDuration(
      sourceDuration: sourceDuration,
      videoDuration: videoDuration,
    );
    if (position < Duration.zero ||
        position >= length ||
        length <= Duration.zero) {
      return 0;
    }
    final elapsed = position.inMicroseconds;
    final remaining = (length - position).inMicroseconds;
    final inLength = math.min(
      math.max(0, fadeIn.inMicroseconds),
      length.inMicroseconds ~/ 2,
    );
    final outLength = math.min(
      math.max(0, fadeOut.inMicroseconds),
      length.inMicroseconds ~/ 2,
    );
    final inGain = inLength == 0 ? 1.0 : (elapsed / inLength).clamp(0.0, 1.0);
    final outGain = outLength == 0
        ? 1.0
        : (remaining / outLength).clamp(0.0, 1.0);
    return math.min(inGain, outGain);
  }
}
