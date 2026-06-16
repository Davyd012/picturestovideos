import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class AudioAnalysisDebugChart extends StatelessWidget {
  const AudioAnalysisDebugChart({
    super.key,
    required this.audioData,
    required this.frames,
    required this.beats,
    required this.currentTime,
  });

  final AudioData? audioData;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final Duration currentTime;

  static const int _waveformBucketCount = 180;
  static const int _envelopePointCount = 180;
  static const int _smoothingWindow = 4;

  @override
  Widget build(BuildContext context) {
    if (audioData == null || audioData!.samples.isEmpty) {
      return Card.outlined(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'Waveform preview appears after import.',
              style: context.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final duration = audioData!.duration > Duration.zero
        ? audioData!.duration
        : Duration(
            microseconds:
                (audioData!.samples.length * Duration.microsecondsPerSecond) ~/
                audioData!.sampleRate,
          );
    final waveformBuckets = _buildWaveformBuckets(audioData!.samples);
    final envelopePoints = _buildEnvelopePoints(frames, duration);

    return Card.outlined(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final chartHeight = compact ? 180.0 : 220.0;
          final contentPadding = compact ? 16.0 : 24.0;
          final spacing = compact ? 12.0 : 16.0;

          return Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analysis preview', style: context.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Waveform, smoothed envelope, beat markers, and playback head share the same timeline.',
                  style: context.textTheme.bodyMedium,
                ),
                SizedBox(height: spacing),
                SizedBox(
                  height: chartHeight,
                  child: CustomPaint(
                    painter: _AudioAnalysisDebugPainter(
                      colors: context.colors,
                      waveformBuckets: waveformBuckets,
                      envelopePoints: envelopePoints,
                      beats: beats,
                      duration: duration,
                      currentTime: currentTime,
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetricChip(
                        label: '${waveformBuckets.length} waveform buckets',
                      ),
                      const SizedBox(width: 12),
                      _MetricChip(label: '${frames.length} analysis frames'),
                      const SizedBox(width: 12),
                      _MetricChip(label: '${beats.length} beats'),
                      const SizedBox(width: 12),
                      _MetricChip(
                        label: 'Cursor ${currentTime.inMilliseconds} ms',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_WaveformBucket> _buildWaveformBuckets(List<double> samples) {
    final bucketSize = math.max(1, samples.length ~/ _waveformBucketCount);
    final buckets = <_WaveformBucket>[];

    for (var start = 0; start < samples.length; start += bucketSize) {
      final end = math.min(start + bucketSize, samples.length);
      var minSample = 1.0;
      var maxSample = -1.0;

      for (var index = start; index < end; index++) {
        final sample = samples[index];
        minSample = math.min(minSample, sample);
        maxSample = math.max(maxSample, sample);
      }

      buckets.add(
        _WaveformBucket(
          min: minSample.clamp(-1.0, 1.0).toDouble(),
          max: maxSample.clamp(-1.0, 1.0).toDouble(),
        ),
      );
    }

    if (buckets.length > _waveformBucketCount) {
      return buckets.take(_waveformBucketCount).toList(growable: false);
    }

    return List.unmodifiable(buckets);
  }

  List<_EnvelopePoint> _buildEnvelopePoints(
    List<AudioFrame> frames,
    Duration duration,
  ) {
    if (frames.isEmpty || duration <= Duration.zero) {
      return const [];
    }

    final smoothed = _smoothFrames(frames);
    final downsampleFactor = math.max(
      1,
      smoothed.length ~/ _envelopePointCount,
    );
    final durationMicros = math.max(1, duration.inMicroseconds);
    final maxEnergy = smoothed.fold<double>(
      0,
      (currentMax, frame) => math.max(currentMax, frame.energy),
    );
    if (maxEnergy == 0) {
      return const [];
    }

    final points = <_EnvelopePoint>[];
    for (var index = 0; index < smoothed.length; index += downsampleFactor) {
      final frame = smoothed[index];
      points.add(
        _EnvelopePoint(
          progress: frame.time.inMicroseconds / durationMicros,
          value: (frame.energy / maxEnergy).clamp(0.0, 1.0).toDouble(),
        ),
      );
    }

    final lastFrame = smoothed.last;
    final lastProgress = lastFrame.time.inMicroseconds / durationMicros;
    if (points.isEmpty || points.last.progress < lastProgress) {
      points.add(
        _EnvelopePoint(
          progress: lastProgress.clamp(0.0, 1.0).toDouble(),
          value: (lastFrame.energy / maxEnergy).clamp(0.0, 1.0).toDouble(),
        ),
      );
    }

    return List.unmodifiable(points);
  }

  List<AudioFrame> _smoothFrames(List<AudioFrame> frames) {
    return List.unmodifiable([
      for (var index = 0; index < frames.length; index++)
        AudioFrame(
          time: frames[index].time,
          energy: _averageEnergy(
            frames: frames,
            centerIndex: index,
            window: _smoothingWindow,
          ),
        ),
    ]);
  }

  double _averageEnergy({
    required List<AudioFrame> frames,
    required int centerIndex,
    required int window,
  }) {
    final halfWindow = window ~/ 2;
    final start = math.max(0, centerIndex - halfWindow);
    final end = math.min(frames.length, centerIndex + halfWindow + 1);
    var sum = 0.0;

    for (var index = start; index < end; index++) {
      sum += frames[index].energy;
    }

    return sum / (end - start);
  }
}

class _AudioAnalysisDebugPainter extends CustomPainter {
  const _AudioAnalysisDebugPainter({
    required this.colors,
    required this.waveformBuckets,
    required this.envelopePoints,
    required this.beats,
    required this.duration,
    required this.currentTime,
  });

  final ColorScheme colors;
  final List<_WaveformBucket> waveformBuckets;
  final List<_EnvelopePoint> envelopePoints;
  final List<Beat> beats;
  final Duration duration;
  final Duration currentTime;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = colors.surfaceContainerLow;
    final waveformPaint = Paint()
      ..color = colors.primaryContainer
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final baselinePaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    final beatPaint = Paint()
      ..color = colors.secondary
      ..strokeWidth = 1.5;
    final playheadPaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2;
    final envelopePaint = Paint()
      ..color = colors.tertiary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final borderRadius = BorderRadius.circular(20);
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, backgroundPaint);
    canvas.clipRRect(rrect);

    final centerY = size.height * 0.62;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      baselinePaint,
    );

    if (duration > Duration.zero) {
      for (final beat in beats) {
        final dx = _resolveX(beat.time, size.width);
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), beatPaint);
      }
    }

    if (waveformBuckets.isNotEmpty) {
      final step = size.width / waveformBuckets.length;
      for (var index = 0; index < waveformBuckets.length; index++) {
        final bucket = waveformBuckets[index];
        final dx = (index + 0.5) * step;
        final top = centerY - (bucket.max * size.height * 0.32);
        final bottom = centerY - (bucket.min * size.height * 0.32);
        canvas.drawLine(Offset(dx, top), Offset(dx, bottom), waveformPaint);
      }
    }

    if (envelopePoints.length > 1) {
      final path = Path();
      for (var index = 0; index < envelopePoints.length; index++) {
        final point = envelopePoints[index];
        final dx = point.progress * size.width;
        final dy = size.height - (point.value * size.height * 0.88);
        if (index == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      canvas.drawPath(path, envelopePaint);
    }

    if (duration > Duration.zero) {
      final playheadX = _resolveX(
        currentTime,
        size.width,
      ).clamp(0.0, size.width);
      final resolvedPlayheadX = playheadX.toDouble();
      canvas.drawLine(
        Offset(resolvedPlayheadX, 0),
        Offset(resolvedPlayheadX, size.height),
        playheadPaint,
      );
    }
  }

  double _resolveX(Duration time, double width) {
    if (duration <= Duration.zero) {
      return 0;
    }

    final progress = time.inMicroseconds / duration.inMicroseconds;
    return (progress.clamp(0.0, 1.0) * width).toDouble();
  }

  @override
  bool shouldRepaint(covariant _AudioAnalysisDebugPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.waveformBuckets != waveformBuckets ||
        oldDelegate.envelopePoints != envelopePoints ||
        oldDelegate.beats != beats ||
        oldDelegate.duration != duration ||
        oldDelegate.currentTime != currentTime;
  }
}

class _WaveformBucket {
  const _WaveformBucket({required this.min, required this.max});

  final double min;
  final double max;
}

class _EnvelopePoint {
  const _EnvelopePoint({required this.progress, required this.value});

  final double progress;
  final double value;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
