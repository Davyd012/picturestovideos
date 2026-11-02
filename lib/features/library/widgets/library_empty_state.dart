import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_error_message.dart';
import 'package:picturestovideos/features/library/widgets/library_status_message.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 64,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.libraryEmptyTitle,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.libraryEmptyDescription,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isImporting
                        ? null
                        : ref
                              .read(libraryViewModelProvider.notifier)
                              .pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.l10n.importImagesHeading),
                  ),
                ),
                if (state.isImporting) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  LibraryErrorMessage(error: state.error),
                ],
                if (state.importStatus != null) ...[
                  const SizedBox(height: 16),
                  LibraryStatusMessage(
                    status: state.importStatus,
                    count: state.statusItemCount,
                  ),
                ],
              ],
            ),
          ),
        ),
        ExpansionTile(
          title: Text(context.l10n.importFolder),
          children: [
            if (defaultTargetPlatform != TargetPlatform.android)
              TextField(
                enabled: !state.isImporting,
                onChanged: ref
                    .read(libraryViewModelProvider.notifier)
                    .folderPathChanged,
                decoration: InputDecoration(
                  hintText: context.l10n.pasteFolderPath,
                ),
              ),
            TextButton.icon(
              onPressed: state.isImporting
                  ? null
                  : defaultTargetPlatform == TargetPlatform.android
                  ? ref
                        .read(libraryViewModelProvider.notifier)
                        .importImagesFromFolderPicker
                  : ref
                        .read(libraryViewModelProvider.notifier)
                        .importImagesFromFolderPath,
              icon: const Icon(Icons.drive_folder_upload_outlined),
              label: Text(context.l10n.importFolder),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          context.l10n.libraryExampleTitle,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final icon in [
              Icons.landscape_outlined,
              Icons.photo_outlined,
            ]) ...[
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Card.filled(
                    child: Icon(
                      icon,
                      size: 48,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (icon == Icons.landscape_outlined) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.libraryExampleDescription,
          style: context.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
