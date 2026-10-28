import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
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
            Text(
              context.l10n.libraryReadyForEditor,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(context.l10n.libraryImportedCount(importedCount)),
                ),
                Chip(
                  label: Text(context.l10n.libraryVisibleCount(visibleCount)),
                ),
                Chip(label: Text(context.l10n.libraryStagedCount(stagedCount))),
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
                  label: Text(context.l10n.libraryImportMore),
                ),
                FilledButton.tonalIcon(
                  onPressed: ref
                      .read(libraryViewModelProvider.notifier)
                      .reviewStagedOpened,
                  icon: const Icon(Icons.drag_indicator),
                  label: Text(context.l10n.libraryReviewStaged),
                ),
                FilledButton.icon(
                  onPressed: () => context.appNavigator.goToAudioEditor(),
                  icon: const Icon(Icons.tune),
                  label: Text(context.l10n.openEditorCount(stagedCount)),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToDownload(),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(context.l10n.libraryGoToExport),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
