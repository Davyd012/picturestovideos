import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/widgets/library_error_message.dart';
import 'package:picturestovideos/features/library/widgets/library_status_message.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class ImportEmptyState extends StatelessWidget {
  const ImportEmptyState({
    required this.audio,
    required this.library,
    required this.onChooseFile,
    required this.onChooseImages,
    required this.onOpenLibrary,
    required this.onResetAudio,
    super.key,
  });

  final AudioImportState audio;
  final LibraryState library;
  final VoidCallback onChooseFile;
  final VoidCallback onChooseImages;
  final VoidCallback onOpenLibrary;
  final VoidCallback onResetAudio;

  @override
  Widget build(BuildContext context) {
    final lang = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lang.importStepsSubtitle,
                    style: context.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(label: Text(lang.importOptionalStep)),
                          const SizedBox(height: 16),
                          Text(
                            lang.importAddMusic,
                            style: context.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.importMusicDescription,
                            style: context.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(
                              audio.source?.fileName ?? lang.importNoAudio,
                            ),
                            subtitle: Text(
                              Platform.isAndroid
                                  ? lang.importAudioFormatsAndroid
                                  : lang.importAudioFormats,
                            ),
                          ),
                          if (audio.isBusy) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: audio.isPickingFile
                                  ? null
                                  : audio.progressValue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              audio.isPickingFile
                                  ? lang.importChoosingFile
                                  : lang.importAnalyzing,
                              style: context.textTheme.bodyMedium,
                            ),
                          ],
                          if (audio.isFailure) ...[
                            const SizedBox(height: 8),
                            Text(
                              audio.errorMessage ?? lang.importAudioFailed,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colors.error,
                              ),
                            ),
                          ],
                          if (audio.hasWarning)
                            Text(
                              audio.warningMessage!,
                              style: context.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: audio.isBusy ? null : onChooseFile,
                    icon: const Icon(Icons.audio_file_outlined),
                    label: Text(lang.importChooseAudio),
                  ),
                  if (audio.isRunning)
                    TextButton(
                      onPressed: onResetAudio,
                      child: Text(lang.importStop),
                    ),
                  const SizedBox(height: 24),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(label: Text(lang.importRequiredStep)),
                          const SizedBox(height: 16),
                          Text(
                            lang.importChooseImagesTitle,
                            style: context.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.importImagesDescription,
                            style: context.textTheme.bodyMedium,
                          ),
                          if (library.items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 96,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: library.items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final item = library.items[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 120,
                                      child: item.thumbnailBytes.isNotEmpty
                                          ? Image.memory(
                                              item.thumbnailBytes,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                            )
                                          : Image.file(
                                              File(item.sourcePath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (library.isImporting) ...[
                            const SizedBox(height: 16),
                            Text(lang.importImagesProgress),
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(),
                          ],
                          LibraryStatusMessage(
                            status: library.importStatus,
                            count: library.statusItemCount,
                          ),
                          LibraryErrorMessage(error: library.error),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: library.isImporting ? null : onChooseImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(lang.importChooseImages),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.importImageFormats,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.importNextStep,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium,
                  ),
                  if (library.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: onOpenLibrary,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(lang.importOpenImages),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
