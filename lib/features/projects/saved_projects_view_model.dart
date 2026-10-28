import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

final savedProjectsViewModelProvider =
    AsyncNotifierProvider<SavedProjectsViewModel, List<ProjectTimeline>>(
      SavedProjectsViewModel.new,
    );

final projectStorageIssuesProvider = Provider<List<ProjectStorageIssue>>((ref) {
  ref.watch(savedProjectsViewModelProvider);
  return ref.watch(projectRepositoryProvider).lastLoadIssues;
});

class SavedProjectsViewModel extends AsyncNotifier<List<ProjectTimeline>> {
  @override
  Future<List<ProjectTimeline>> build() =>
      ref.read(projectRepositoryProvider).loadAll();

  Future<bool> saveCurrent() async {
    final project = ref.read(timelineViewModelProvider).asData?.value.project;
    if (project == null) return false;
    state = const AsyncLoading();
    try {
      await ref.read(projectRepositoryProvider).save(project);
      state = AsyncData(await ref.read(projectRepositoryProvider).loadAll());
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> open(ProjectTimeline project) async {
    await ref.read(playbackViewModelProvider.future);
    await ref.read(playbackViewModelProvider.notifier).reset();
    await ref.read(timelineViewModelProvider.future);
    ref
        .read(editorMediaSelectionViewModelProvider.notifier)
        .restoreProject(project);
    ref.read(timelineViewModelProvider.notifier).projectOpened(project);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(projectRepositoryProvider).loadAll(),
    );
  }
}
