import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/audio_import/audio_import_state.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/audio_import/widgets/import_empty_state.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class AudioImportScreen extends ConsumerWidget {
  const AudioImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioImportViewModelProvider);
    final library = ref.watch(libraryViewModelProvider);
    ref.listen(playbackViewModelProvider, (_, next) {
      final playback = next.value;
      if (playback != null && playback.hasBeatMap) {
        ref
            .read(eventSystemViewModelProvider.notifier)
            .dispatchForPlaybackTime(playback.currentTime);
      }
    });
    return AppShellScaffold(
      currentRoute: AppRoutes.importAudio,
      title: context.l10n.importMediaTitle,
      body: audio.hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.importAudioFailed),
                  Text(audio.error.toString()),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(audioImportViewModelProvider),
                    child: Text(context.l10n.importRetry),
                  ),
                ],
              ),
            )
          : ImportEmptyState(
              audio: audio.value ?? const AudioImportState.initial(),
              library: library,
              onChooseFile: () => ref
                  .read(audioImportViewModelProvider.notifier)
                  .pickAudioFile(),
              onChooseImages: () =>
                  ref.read(libraryViewModelProvider.notifier).pickImages(),
              onOpenLibrary: () => context.appNavigator.goToLibrary(),
              onResetAudio: () =>
                  ref.read(audioImportViewModelProvider.notifier).stopImport(),
            ),
    );
  }
}
