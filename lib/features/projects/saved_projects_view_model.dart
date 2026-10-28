import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/library/imported_image_cleanup_policy.dart';
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
    final previousProject = state.asData?.value
        .where((saved) => saved.id == project.id)
        .firstOrNull;
    state = const AsyncLoading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      await repository.save(project);
      final savedProjects = await repository.loadAll();
      state = AsyncData(savedProjects);
      await _cleanupSupersededImages(
        previousProject: previousProject,
        currentProject: project,
        savedProjects: savedProjects,
        storageIssues: repository.lastLoadIssues,
      );
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> _cleanupSupersededImages({
    required ProjectTimeline? previousProject,
    required ProjectTimeline currentProject,
    required List<ProjectTimeline> savedProjects,
    required List<ProjectStorageIssue> storageIssues,
  }) async {
    if (previousProject == null || storageIssues.isNotEmpty) return;
    final obsoletePaths = _imagePaths(previousProject)
        .difference(_imagePaths(currentProject));
    if (obsoletePaths.isEmpty) return;

    try {
      final retainedAssets = await ref
          .read(savedImageAssetRepositoryProvider)
          .loadAll();
      final activeProject = ref
          .read(timelineViewModelProvider)
          .asData
          ?.value
          .project;
      final candidates = unreferencedImportedImagePaths(
        candidates: obsoletePaths,
        retainedAssets: retainedAssets,
        projects: [...savedProjects, ?activeProject],
      );
      if (candidates.isEmpty) return;
      await ref
          .read(imageImportRepositoryProvider)
          .removeImportedImages(candidates);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            'SavedProjectsViewModel',
            error,
            stackTrace,
            message: 'Cleaning up superseded project images failed',
          );
    }
  }

  Set<String> _imagePaths(ProjectTimeline project) {
    final paths = <String>{};
    for (final track in project.tracks) {
      for (final event in track.events) {
        final payload = event.payload;
        if (payload is MediaTrackClipPayload) paths.add(payload.sourcePath);
      }
    }
    return paths;
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
