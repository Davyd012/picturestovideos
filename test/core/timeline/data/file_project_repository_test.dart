import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/file_project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  late Directory supportDirectory;
  late FileProjectRepository repository;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'project-repository-test-',
    );
    repository = FileProjectRepository(
      serializer: const ProjectSerializer(),
      supportDirectory: () async => supportDirectory,
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test(
    'saves independent files and replaces by stable project identity',
    () async {
      await repository.save(_project('alpha', name: 'First'));
      await repository.save(_project('beta', name: 'Other'));
      await repository.save(_project('alpha', name: 'Updated'));

      final reopened = await repository.loadAll();
      expect(reopened, hasLength(2));
      expect({for (final project in reopened) project.id}, {'alpha', 'beta'});
      expect(
        reopened.singleWhere((project) => project.id == 'alpha').name,
        'Updated',
      );
      final clips = reopened
          .singleWhere((project) => project.id == 'alpha')
          .tracks
          .single
          .events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(clips.map((clip) => clip.clipId), [
        'occurrence-a',
        'occurrence-b',
      ]);
      expect(clips.first.imageFit, VideoTemplateImageFit.cover);
      expect(clips.first.cropTransform.focalX, 0.5);
      expect(clips.first.caption, 'First occurrence');
      expect(clips.last.imageFit, VideoTemplateImageFit.contain);
      expect(clips.last.cropTransform.focalY, 0.75);
      expect(clips.last.caption, 'Second occurrence');
      expect(clips.last.motionOverride, ClipMotionPreset.slowZoomOut);
      expect(clips.last.transitionOverride, ClipTransitionType.dissolve);

      await repository.save(
        reopened.singleWhere((project) => project.id == 'alpha'),
      );
      final reopenedAgain = await repository.loadAll();
      final repeatedClips = reopenedAgain
          .singleWhere((project) => project.id == 'alpha')
          .tracks
          .single
          .events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(repeatedClips.map((clip) => clip.clipId), [
        'occurrence-a',
        'occurrence-b',
      ]);
      expect(repeatedClips.map((clip) => clip.mediaId), [
        'same-photo',
        'same-photo',
      ]);
      expect(repeatedClips.map((clip) => clip.imageFit), [
        VideoTemplateImageFit.cover,
        VideoTemplateImageFit.contain,
      ]);
      expect(repeatedClips.map((clip) => clip.caption), [
        'First occurrence',
        'Second occurrence',
      ]);
      expect(repeatedClips.last.motionOverride, ClipMotionPreset.slowZoomOut);
      expect(
        repeatedClips.last.transitionOverride,
        ClipTransitionType.dissolve,
      );
      expect(repository.lastLoadIssues, isEmpty);
    },
  );

  test(
    'loads legacy schemas through the repository and reopens migrations',
    () async {
      const legacyClip = MediaTrackClipPayload(
        mediaId: 'same-photo',
        title: 'photo.jpg',
        tagline: 'Imported',
        start: Duration.zero,
        end: Duration(seconds: 2),
        sourcePath: 'photo.jpg',
        imageFit: VideoTemplateImageFit.cover,
      );
      final payload = legacyClip.toJson()
        ..remove('clipId')
        ..remove('caption')
        ..remove('captionSupportingLine')
        ..remove('captionSettings')
        ..remove('cropTransform')
        ..remove('motionIntensity')
        ..remove('useStyleMotionIntensity')
        ..remove('transitionOverride')
        ..remove('transitionDurationMs');
      final projectDirectory = Directory('${supportDirectory.path}/projects');
      await projectDirectory.create(recursive: true);

      for (
        var version = 0;
        version <= ProjectSerializer.currentSchemaVersion;
        version++
      ) {
        final id = 'repository-legacy-$version';
        final encodedId = base64Url.encode(utf8.encode(id)).replaceAll('=', '');
        await File('${projectDirectory.path}/$encodedId.json').writeAsString(
          jsonEncode({
            'schemaVersion': version,
            'id': id,
            'name': id,
            'beatMap': {
              'beats': <Object?>[],
              'bpm': 0,
              'averageBeatIntervalMs': 1000,
            },
            'tracks': [
              {
                'id': 'track-media',
                'name': 'Images',
                'events': [
                  {'timeMs': 0, 'type': 'image', 'payload': payload},
                  {'timeMs': 2000, 'type': 'image', 'payload': payload},
                ],
              },
            ],
          }),
        );
      }

      final migrated = await repository.loadAll();
      expect(migrated, hasLength(ProjectSerializer.currentSchemaVersion + 1));
      for (final project in migrated) {
        final clips = project.tracks.single.events
            .map((event) => event.payload as MediaTrackClipPayload)
            .toList();
        expect(clips.map((clip) => clip.clipId).toSet(), hasLength(2));
        expect(clips.map((clip) => clip.caption), ['photo.jpg', 'photo.jpg']);
        await repository.save(project);
      }

      final reopened = await repository.loadAll();
      final reopenedAgain = await repository.loadAll();
      expect(reopenedAgain, hasLength(migrated.length));
      for (final project in reopened) {
        final firstIds = project.tracks.single.events
            .map((event) => (event.payload as MediaTrackClipPayload).clipId)
            .toList();
        final secondIds = reopenedAgain
            .singleWhere((candidate) => candidate.id == project.id)
            .tracks
            .single
            .events
            .map((event) => (event.payload as MediaTrackClipPayload).clipId)
            .toList();
        expect(secondIds, firstIds, reason: project.id);
        expect(firstIds.toSet(), hasLength(2), reason: project.id);
      }
    },
  );

  test('recovers an interrupted commit from its backup', () async {
    final original = _project('recoverable', name: 'Last good copy');
    await repository.save(original);
    final projectDirectory = Directory('${supportDirectory.path}/projects');
    final current =
        (await projectDirectory
                    .list()
                    .where((entry) => entry.path.endsWith('.json'))
                    .toList())
                .single
            as File;
    final backup = File('${current.path}.bak');
    await current.rename(backup.path);
    final interrupted = await projectDirectory.createTemp('pending-');
    await File('${interrupted.path}/partial').writeAsString('partial');

    final reopened = await repository.loadAll();

    expect(reopened.map((project) => project.id), ['recoverable']);
    expect(reopened.single.name, 'Last good copy');
    expect(repository.lastLoadIssues.single.recoveredFromBackup, isTrue);
    expect(await File(current.path).exists(), isTrue);
    expect(await backup.exists(), isTrue);
    expect(
      (await projectDirectory
              .list()
              .where((entry) => entry is Directory)
              .toList())
          .where((entry) => entry.path.contains('pending-')),
      isEmpty,
    );
  });

  test('corrupt project does not hide valid projects', () async {
    await repository.save(_project('valid'));
    final projectDirectory = Directory('${supportDirectory.path}/projects');
    await File('${projectDirectory.path}/broken.json').writeAsString('{');

    final reopened = await repository.loadAll();

    expect(reopened.map((project) => project.id), ['valid']);
    expect(repository.lastLoadIssues, hasLength(1));
    expect(repository.lastLoadIssues.single.recoveredFromBackup, isFalse);
  });

  test(
    'newer schema project is preserved while valid projects still load',
    () async {
      await repository.save(_project('valid'));
      final projectDirectory = Directory('${supportDirectory.path}/projects');
      const futureDocument =
          '{"schemaVersion":999,"id":"future","data":"keep"}';
      final futureFile = File('${projectDirectory.path}/future.json');
      await futureFile.writeAsString(futureDocument);

      final reopened = await repository.loadAll();

      expect(reopened.map((project) => project.id), ['valid']);
      expect(repository.lastLoadIssues, hasLength(1));
      expect(repository.lastLoadIssues.single.projectFile, 'future.json');
      expect(repository.lastLoadIssues.single.recoveredFromBackup, isFalse);
      expect(await futureFile.readAsString(), futureDocument);
    },
  );

  test('corrupt current file restores its previous valid generation', () async {
    await repository.save(_project('replaceable', name: 'Previous'));
    await repository.save(_project('replaceable', name: 'Current'));
    final projectDirectory = Directory('${supportDirectory.path}/projects');
    final current =
        (await projectDirectory
                    .list()
                    .where((entry) => entry.path.endsWith('.json'))
                    .toList())
                .single
            as File;
    await current.writeAsString('not-json', flush: true);

    final reopened = await repository.loadAll();

    expect(reopened.single.name, 'Previous');
    expect(repository.lastLoadIssues.single.recoveredFromBackup, isTrue);
    expect(
      (await projectDirectory
              .list()
              .where((entry) => entry.path.contains('.corrupt-'))
              .toList())
          .whereType<File>(),
      hasLength(1),
    );
  });

  test('failure after backup rotation restores the original project', () async {
    await repository.save(_project('stable', name: 'Keep me'));
    final failingRepository = FileProjectRepository(
      serializer: const ProjectSerializer(),
      supportDirectory: () async => supportDirectory,
      saveObserver: (stage) async {
        if (stage == ProjectSaveStage.previousGenerationBackedUp) {
          throw const FileSystemException('Injected commit failure');
        }
      },
    );

    await expectLater(
      failingRepository.save(_project('stable', name: 'Should not commit')),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.loadAll()).single.name, 'Keep me');
    final projectDirectory = Directory('${supportDirectory.path}/projects');
    expect(
      (await projectDirectory
              .list()
              .where((entry) => entry is Directory)
              .toList())
          .where((entry) => entry.path.contains('pending-')),
      isEmpty,
    );
  });

  test('failure after staging leaves the current project untouched', () async {
    await repository.save(_project('stable-before-stage', name: 'Keep me'));
    final failingRepository = FileProjectRepository(
      serializer: const ProjectSerializer(),
      supportDirectory: () async => supportDirectory,
      saveObserver: (stage) async {
        if (stage == ProjectSaveStage.stagedAndValidated) {
          throw const FileSystemException('Injected staging failure');
        }
      },
    );

    await expectLater(
      failingRepository.save(
        _project('stable-before-stage', name: 'Should not commit'),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.loadAll()).single.name, 'Keep me');
  });

  test(
    'staged project is valid JSON before it replaces the current file',
    () async {
      final staged = _project('unicode', name: 'Norge — Привет');
      await repository.save(staged);
      final projectDirectory = Directory('${supportDirectory.path}/projects');
      final savedFile =
          (await projectDirectory
                      .list()
                      .where((entry) => entry.path.endsWith('.json'))
                      .toList())
                  .single
              as File;
      final encoded = jsonDecode(await savedFile.readAsString()) as Map;

      expect(encoded['id'], 'unicode');
      expect((await repository.loadAll()).single.name, 'Norge — Привет');
    },
  );
}

ProjectTimeline _project(String id, {String? name}) => ProjectTimeline(
  id: id,
  name: name ?? id,
  beatMap: const BeatMap(
    beats: [],
    bpm: 0,
    averageBeatInterval: Duration(seconds: 1),
  ),
  tracks: [
    TimelineTrack(
      id: 'track-media',
      name: 'Photos',
      events: [
        BeatEvent(
          time: Duration.zero,
          type: 'image',
          payload: const MediaTrackClipPayload(
            clipId: 'occurrence-a',
            mediaId: 'same-photo',
            title: 'Photo',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 2),
            sourcePath: 'photo.jpg',
            imageFit: VideoTemplateImageFit.cover,
            cropTransform: ImageCropTransform(focalX: 0.5, focalY: -0.25),
            caption: 'First occurrence',
          ),
        ),
        BeatEvent(
          time: const Duration(seconds: 2),
          type: 'image',
          payload: const MediaTrackClipPayload(
            clipId: 'occurrence-b',
            mediaId: 'same-photo',
            title: 'Photo',
            tagline: '',
            start: Duration(seconds: 2),
            end: Duration(seconds: 4),
            sourcePath: 'photo.jpg',
            imageFit: VideoTemplateImageFit.contain,
            cropTransform: ImageCropTransform(focalX: -0.5, focalY: 0.75),
            caption: 'Second occurrence',
            motionOverride: ClipMotionPreset.slowZoomOut,
            transitionOverride: ClipTransitionType.dissolve,
            transitionDuration: Duration(milliseconds: 400),
          ),
        ),
      ],
    ),
  ],
);
