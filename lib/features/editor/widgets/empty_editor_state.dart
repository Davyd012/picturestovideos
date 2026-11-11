import 'package:flutter/material.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class EmptyEditorState extends StatelessWidget {
  const EmptyEditorState({
    super.key,
    required this.hasQueuedImages,
    required this.onAdd,
    this.onOpenMarkers,
  });

  final bool hasQueuedImages;
  final VoidCallback onAdd;
  final VoidCallback? onOpenMarkers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.emptyEditorTitle,
                  style: context.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.emptyEditorDescription,
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      hasQueuedImages
                          ? l10n.emptyEditorAddQueued
                          : l10n.emptyEditorAddImages,
                    ),
                  ),
                ),
                if (onOpenMarkers != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenMarkers,
                    icon: const Icon(Icons.bookmark_border),
                    label: Text(l10n.editorMarkers),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.emptyEditorSteps, style: context.textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final (index, label) in [
          l10n.emptyEditorOrder,
          l10n.emptyEditorEdit,
          l10n.emptyEditorExport,
        ].indexed)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(label),
            ),
          ),
        const SizedBox(height: 24),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.emptyEditorToolsHint),
          ),
        ),
      ],
    );
  }
}
