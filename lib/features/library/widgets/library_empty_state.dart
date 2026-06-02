import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({
    required this.visibleCount,
    required this.selectedCount,
    super.key,
  });

  final int visibleCount;
  final int selectedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final viewModel = ref.read(libraryViewModelProvider.notifier);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Import images', style: context.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Import images, stage the strongest frames, and send them into the beat-synced editor flow.',
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Visible: $visibleCount')),
                const Chip(label: Text('Imported: 0')),
                Chip(label: Text('In editor: $selectedCount')),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              enabled: !state.isImporting,
              onChanged: viewModel.folderPathChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.folder_open_outlined),
                hintText: 'Paste folder path',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.isImporting ? null : viewModel.pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pick images'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isImporting
                      ? null
                      : viewModel.importImagesFromFolderPath,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: const Text('Import folder'),
                ),
              ],
            ),
            if (state.isImporting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (state.statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(state.statusMessage!, style: context.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
