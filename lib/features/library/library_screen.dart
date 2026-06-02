import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_browse_view.dart';
import 'package:picturestovideos/features/library/widgets/staged_images_screen.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final editorSelection = ref.watch(editorMediaSelectionViewModelProvider);

    return AppShellScaffold(
      currentRoute: AppRoutes.library,
      title: 'Library',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: editorSelection.hasSelection
                ? () => context.appNavigator.goToAudioEditor()
                : null,
            icon: const Icon(Icons.tune),
            label: Text('Open editor (${editorSelection.selectedCount})'),
          ),
        ),
      ],
      body: state.isReviewingStaged
          ? const StagedImagesScreen()
          : const LibraryBrowseView(),
    );
  }
}
