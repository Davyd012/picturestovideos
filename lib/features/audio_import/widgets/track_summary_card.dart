import 'package:flutter/material.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class TrackSummaryCard extends StatelessWidget {
  const TrackSummaryCard({
    required this.state,
    required this.beatCount,
    required this.bpm,
    super.key,
  });

  final AudioImportState state;
  final int beatCount;
  final double bpm;

  @override
  Widget build(BuildContext context) {
    final source = state.source;
    final audioData = state.audioData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track summary', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _MetricTile(label: 'File name', value: source?.fileName ?? '-'),
                _MetricTile(
                  label: 'Duration',
                  value: audioData == null
                      ? '-'
                      : _formatDuration(audioData.duration),
                ),
                _MetricTile(
                  label: 'Sample rate',
                  value: audioData == null ? '-' : '${audioData.sampleRate} Hz',
                ),
                const _MetricTile(label: 'Bit depth', value: '16-bit'),
                _MetricTile(
                  label: 'Channels',
                  value: audioData == null ? '-' : '${audioData.channelCount}',
                ),
                _MetricTile(
                  label: 'BPM',
                  value: bpm <= 0 ? '-' : bpm.toStringAsFixed(1),
                ),
                const _MetricTile(label: 'Key', value: 'Unknown'),
                _MetricTile(label: 'Beat count', value: '$beatCount'),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }
}
