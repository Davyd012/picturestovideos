import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_frame.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class WaveformPreviewCard extends StatelessWidget {
  const WaveformPreviewCard({
    required this.audioData,
    required this.frames,
    required this.beats,
    required this.bpm,
    required this.currentTime,
    super.key,
  });

  final AudioData audioData;
  final List<AudioFrame> frames;
  final List<Beat> beats;
  final double bpm;
  final Duration currentTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis preview', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 136,
              child: CustomPaint(
                painter: _WaveformPreviewPainter(
                  frames: frames,
                  beats: beats,
                  duration: audioData.duration,
                  currentTime: currentTime,
                  lineColor: context.colors.primary,
                  markerColor: context.colors.secondary,
                  outlineColor: context.colors.outlineVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _Metric(
                  label: 'Duration',
                  value: _formatDuration(audioData.duration),
                ),
                _Metric(
                  label: 'BPM',
                  value: bpm <= 0 ? '-' : bpm.toStringAsFixed(1),
                ),
                const _Metric(label: 'Key', value: 'Unknown'),
                _Metric(label: 'Beats', value: '${beats.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _WaveformPreviewPainter extends CustomPainter {
  const _WaveformPreviewPainter({
    required this.frames,
    required this.beats,
    required this.duration,
    required this.currentTime,
    required this.lineColor,
    required this.markerColor,
    required this.outlineColor,
  });

  final List<AudioFrame> frames;
  final List<Beat> beats;
  final Duration duration;
  final Duration currentTime;
  final Color lineColor;
  final Color markerColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      outlinePaint,
    );

    final waveformPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final centerY = size.height * 0.45;
    final maxEnergy = frames.fold<double>(
      0,
      (currentMax, frame) => math.max(currentMax, frame.energy.abs()),
    );
    final source = frames.isEmpty ? _fallbackFrames(duration) : frames;

    for (var index = 0; index < source.length; index++) {
      final frame = source[index];
      final x = source.length <= 1
          ? size.width / 2
          : (index / (source.length - 1)) * size.width;
      final normalized = maxEnergy <= 0
          ? 0.5
          : (frame.energy.abs() / maxEnergy).clamp(0.08, 1.0);
      final barHeight = normalized * size.height * 0.56;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        waveformPaint,
      );
    }

    final markerPaint = Paint()
      ..color = markerColor
      ..strokeWidth = 2;
    final markerTop = size.height * 0.78;
    for (final beat in beats.take(64)) {
      final x = _xForTime(beat.time, size.width);
      canvas.drawLine(
        Offset(x, markerTop),
        Offset(x, size.height),
        markerPaint,
      );
    }

    final playheadX = _xForTime(currentTime, size.width);
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(_WaveformPreviewPainter oldDelegate) {
    return oldDelegate.frames != frames ||
        oldDelegate.beats != beats ||
        oldDelegate.currentTime != currentTime ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.outlineColor != outlineColor;
  }

  double _xForTime(Duration time, double width) {
    if (duration <= Duration.zero) {
      return 0;
    }
    final totalMicros = math.max(1, duration.inMicroseconds);
    final progress = time.inMicroseconds / totalMicros;
    return progress.clamp(0.0, 1.0) * width;
  }

  List<AudioFrame> _fallbackFrames(Duration duration) {
    return [
      for (var index = 0; index < 48; index++)
        AudioFrame(
          time: duration * index ~/ 48,
          energy: math.sin(index * 0.55).abs(),
        ),
    ];
  }
}
