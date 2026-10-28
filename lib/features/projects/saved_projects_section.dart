import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/projects/saved_projects_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class SavedProjectsSection extends ConsumerWidget {
  const SavedProjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(savedProjectsViewModelProvider);
    final storageIssues = ref.watch(projectStorageIssuesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.savedProjects, style: context.textTheme.titleLarge),
        if (storageIssues.isNotEmpty)
          Card.outlined(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(context.l10n.projectStorageRecoveryNotice),
            ),
          ),
        switch (projects) {
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncError() => ListTile(
            title: Text(context.l10n.projectsLoadFailed),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(savedProjectsViewModelProvider.notifier).refresh(),
              child: Text(context.l10n.retry),
            ),
          ),
          AsyncData(:final value) when value.isEmpty => ListTile(
            title: Text(context.l10n.noSavedProjects),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final project in value)
                Card.outlined(
                  child: ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: Text(project.name),
                    subtitle: Text(project.template.aspectRatio.label),
                    trailing: IconButton(
                      tooltip: context.l10n.openProject,
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        await ref
                            .read(savedProjectsViewModelProvider.notifier)
                            .open(project);
                        if (context.mounted) {
                          context.appNavigator.goToAudioEditor();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        },
      ],
    );
  }
}
