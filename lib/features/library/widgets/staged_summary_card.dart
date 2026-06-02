import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class StagedSummaryCard extends ConsumerWidget {
  const StagedSummaryCard({
    required this.importedCount,
    required this.visibleCount,
    required this.stagedCount,
    super.key,
  });

  final int importedCount;
  final int visibleCount;
  final int stagedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ready for editor', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Imported: $importedCount')),
                Chip(label: Text('Visible: $visibleCount')),
                Chip(label: Text('Staged: $stagedCount')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: ref
                      .read(libraryViewModelProvider.notifier)
                      .pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import more'),
                ),
                FilledButton.tonalIcon(
                  onPressed: ref
                      .read(libraryViewModelProvider.notifier)
                      .reviewStagedOpened,
                  icon: const Icon(Icons.drag_indicator),
                  label: const Text('Review staged'),
                ),
                FilledButton.icon(
                  onPressed: () => context.appNavigator.goToAudioEditor(),
                  icon: const Icon(Icons.tune),
                  label: const Text('Open editor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToDownload(),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Go to export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
