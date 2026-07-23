import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class SelectionActionBar extends ConsumerWidget {
  const SelectionActionBar({required this.selectedItems, super.key});

  final List<LibraryMediaItem> selectedItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text('${selectedItems.length} selected')),
                FilledButton.tonalIcon(
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () => _stageSelected(ref),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Stage selected'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () => _removeSelected(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.removeImported),
                ),
                TextButton.icon(
                  onPressed: ref
                      .read(libraryViewModelProvider.notifier)
                      .clearItemSelection,
                  icon: Icon(
                    Icons.clear,
                    color: context.colors.onSurfaceVariant,
                  ),
                  label: const Text('Clear selection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stageSelected(WidgetRef ref) {
    ref
        .read(editorMediaSelectionViewModelProvider.notifier)
        .addAllMedia(selectedItems);
    ref.read(libraryViewModelProvider.notifier).clearItemSelection();
  }

  Future<void> _removeSelected(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeImportedTitle),
        content: Text(context.l10n.removeImportedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(libraryViewModelProvider.notifier).removeImportedImages({
      for (final item in selectedItems) item.id,
    });
  }
}
