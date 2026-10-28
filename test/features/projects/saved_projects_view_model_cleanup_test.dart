import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/media/data/saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/data/shared_preferences_saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/projects/saved_projects_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test(
    'saving a project removes source files it no longer references',
    () async {
      const oldPath = '/app/imported_images/old.png';
      final repository = _MemoryProjectRepository([
        _project('edited', [oldPath]),
      ]);
      final imageRepository = _MemoryImageImportRepository();
      final container = _container(repository, imageRepository);
      addTearDown(container.dispose);

      await _saveReplacement(container, _project('edited', const []));

      expect(imageRepository.removedPaths, [
        {oldPath},
      ]);
    },
  );

  test('saving retains files still used by another project', () async {
    const sharedPath = '/app/imported_images/shared.png';
    final repository = _MemoryProjectRepository([
      _project('edited', [sharedPath]),
      _project('other', [sharedPath]),
    ]);
    final imageRepository = _MemoryImageImportRepository();
    final container = _container(repository, imageRepository);
    addTearDown(container.dispose);

    await _saveReplacement(container, _project('edited', const []));

    expect(imageRepository.removedPaths, isEmpty);
  });

  test('saving retains files that are still in the Library', () async {
    const sharedPath = '/app/imported_images/shared.png';
    final repository = _MemoryProjectRepository([
      _project('edited', [sharedPath]),
    ]);
    final imageRepository = _MemoryImageImportRepository();
    final container = _container(
      repository,
      imageRepository,
      assets: [_asset(sharedPath)],
    );
    addTearDown(container.dispose);

    await _saveReplacement(container, _project('edited', const []));

    expect(imageRepository.removedPaths, isEmpty);
  });

  test('storage issues prevent project-image cleanup', () async {
    const oldPath = '/app/imported_images/old.png';
    final repository = _MemoryProjectRepository(
      [
        _project('edited', [oldPath]),
      ],
      issues: const [
        ProjectStorageIssue(
          projectFile: 'unreadable.json',
          recoveredFromBackup: false,
        ),
      ],
    );
    final imageRepository = _MemoryImageImportRepository();
    final container = _container(repository, imageRepository);
    addTearDown(container.dispose);

    await _saveReplacement(container, _project('edited', const []));

    expect(imageRepository.removedPaths, isEmpty);
  });
}

ProviderContainer _container(
  _MemoryProjectRepository projectRepository,
  _MemoryImageImportRepository imageRepository, {
  List<SavedImageAsset> assets = const [],
}) {
  return ProviderContainer(
    overrides: [
      projectRepositoryProvider.overrideWithValue(projectRepository),
      imageImportRepositoryProvider.overrideWithValue(imageRepository),
      savedImageAssetRepositoryProvider.overrideWithValue(
        _MemorySavedImageAssetRepository(assets),
      ),
    ],
  );
}

Future<void> _saveReplacement(
  ProviderContainer container,
  ProjectTimeline replacement,
) async {
  await container.read(savedProjectsViewModelProvider.future);
  await container.read(timelineViewModelProvider.future);
  container.read(timelineViewModelProvider.notifier).projectOpened(replacement);
  expect(
    await container.read(savedProjectsViewModelProvider.notifier).saveCurrent(),
    isTrue,
  );
}

ProjectTimeline _project(String id, List<String> sourcePaths) {
  var time = Duration.zero;
  final events = <BeatEvent>[];
  for (final sourcePath in sourcePaths) {
    final start = time;
    time += const Duration(seconds: 2);
    events.add(
      BeatEvent(
        time: start,
        type: 'image',
        payload: MediaTrackClipPayload(
          clipId: '$id-$sourcePath',
          mediaId: sourcePath,
          title: sourcePath.split('/').last,
          tagline: '',
          start: start,
          end: time,
          sourcePath: sourcePath,
          imageFit: VideoTemplateImageFit.cover,
        ),
      ),
    );
  }
  return ProjectTimeline(
    id: id,
    name: id,
    beatMap: const BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 1),
    ),
    tracks: [TimelineTrack(id: 'track-media', name: 'Images', events: events)],
  );
}

SavedImageAsset _asset(String path) => SavedImageAsset(
  id: path,
  fileName: path.split('/').last,
  sourcePath: path,
  byteLength: 10,
  importedOn: DateTime(2026),
);

class _MemoryProjectRepository implements ProjectRepository {
  _MemoryProjectRepository(
    List<ProjectTimeline> projects, {
    this.issues = const [],
  }) : _projects = [...projects];

  final List<ProjectTimeline> _projects;
  final List<ProjectStorageIssue> issues;

  @override
  List<ProjectStorageIssue> get lastLoadIssues => issues;

  @override
  Future<List<ProjectTimeline>> loadAll() async => List.unmodifiable(_projects);

  @override
  Future<void> save(ProjectTimeline project) async {
    _projects.removeWhere((saved) => saved.id == project.id);
    _projects.add(project);
  }
}

class _MemoryImageImportRepository implements ImageImportRepository {
  final List<Set<String>> removedPaths = [];

  @override
  Future<List<ImportedImageAsset>> pickImages() async => const [];

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPath(
    String folderPath,
  ) async => const [];

  @override
  Future<List<ImportedImageAsset>> importImagesFromFolderPicker() async =>
      const [];

  @override
  Future<void> removeImportedImages(Set<String> sourcePaths) async {
    removedPaths.add(Set.unmodifiable(sourcePaths));
  }
}

class _MemorySavedImageAssetRepository implements SavedImageAssetRepository {
  _MemorySavedImageAssetRepository(this.assets);

  final List<SavedImageAsset> assets;

  @override
  Future<void> clear() async => assets.clear();

  @override
  Future<List<SavedImageAsset>> loadAll() async => List.unmodifiable(assets);

  @override
  Future<void> removeAll(Set<String> ids) async {
    assets.removeWhere((asset) => ids.contains(asset.id));
  }

  @override
  Future<void> upsertAll(List<SavedImageAsset> newAssets) async {
    for (final asset in newAssets) {
      assets.removeWhere((saved) => saved.id == asset.id);
      assets.add(asset);
    }
  }
}
