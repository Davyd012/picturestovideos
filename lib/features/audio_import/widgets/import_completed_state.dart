import 'package:flutter/material.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/widgets/track_summary_card.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ImportCompletedState extends StatelessWidget {
  const ImportCompletedState({
    required this.state,
    required this.beatCount,
    required this.bpm,
    required this.onGoToEditor,
    required this.onImportAnother,
    required this.onViewPipeline,
    super.key,
  });

  final AudioImportState state;
  final int beatCount;
  final double bpm;
  final VoidCallback onGoToEditor;
  final VoidCallback onImportAnother;
  final VoidCallback onViewPipeline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text('Import complete', style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Your track is ready in the workspace.',
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TrackSummaryCard(state: state, beatCount: beatCount, bpm: bpm),
              if (state.source != null) ...[
                const SizedBox(height: 16),
                _RecentImportsCard(fileName: state.source!.fileName),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: onGoToEditor,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Go to editor'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImportAnother,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import another file'),
                  ),
                  TextButton.icon(
                    onPressed: onViewPipeline,
                    icon: const Icon(Icons.timeline),
                    label: const Text('View pipeline progress'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentImportsCard extends StatelessWidget {
  const _RecentImportsCard({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Recent imports'),
        subtitle: Text(fileName),
      ),
    );
  }
}
