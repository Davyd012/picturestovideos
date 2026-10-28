/// Uses nearest-frame rounding with half-frame ties rounded away from zero.
class FrameTimeQuantizer {
  const FrameTimeQuantizer(this.frameRate);

  final int frameRate;

  int frameCountForDuration(Duration duration) {
    if (frameRate <= 0) throw ArgumentError.value(frameRate, 'frameRate');
    if (duration <= Duration.zero) return 1;
    final count =
        (duration.inMicroseconds * frameRate +
            Duration.microsecondsPerSecond ~/ 2) ~/
        Duration.microsecondsPerSecond;
    return count.clamp(1, 1 << 30);
  }

  /// Returns normalized progress for a sampled output frame. The final
  /// encoded frame reaches 1.0, matching frame-indexed renderer filters.
  double progressForFrame({
    required Duration time,
    required Duration start,
    required Duration end,
  }) {
    final span = end - start;
    if (span <= Duration.zero) return 0;
    final frameCount = frameCountForDuration(span);
    if (frameCount <= 1) return 0;
    final lastFrame = quantize(
      Duration(
        microseconds:
            (frameCount - 1) * Duration.microsecondsPerSecond ~/ frameRate,
      ),
    );
    if (lastFrame <= Duration.zero) return 0;
    return ((time - start).inMicroseconds / lastFrame.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  Duration quantize(Duration time) {
    if (frameRate <= 0) throw ArgumentError.value(frameRate, 'frameRate');
    final value = time.inMicroseconds;
    final sign = value < 0 ? -1 : 1;
    final magnitude = value.abs();
    final frame =
        (magnitude * frameRate + Duration.microsecondsPerSecond ~/ 2) ~/
        Duration.microsecondsPerSecond;
    final frameMicros =
        (frame * Duration.microsecondsPerSecond + frameRate ~/ 2) ~/ frameRate;
    return Duration(microseconds: sign * frameMicros);
  }
}
