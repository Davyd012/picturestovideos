import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/data/device_audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/file_project_repository.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/image_file_picker.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/projects/project_media_recovery.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test(
    'relinks repeated image and audio sources without losing edits',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'picturestovideos-relink-test-',
      );
      final replacement = File('${dir.path}/replacement.jpg');
      final replacementAudio = File('${dir.path}/replacement.mp3');
      await replacement.writeAsBytes([1]);
      await replacementAudio.writeAsBytes([2]);
      addTearDown(() async {
        await replacement.delete();
        await replacementAudio.delete();
        await dir.delete(recursive: true);
      });
      const first = MediaTrackClipPayload(
        clipId: 'first',
        mediaId: 'photo',
        title: 'Photo',
        tagline: '',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: 'missing.jpg',
        imageFit: VideoTemplateImageFit.cover,
        cropTransform: ImageCropTransform(focalX: -0.7, focalY: 0.3, zoom: 1.5),
        caption: 'Memory',
        motionOverride: ClipMotionPreset.gentlePan,
        motionIntensity: ClipMotionIntensity.subtle,
        useStyleMotionIntensity: false,
        transitionOverride: ClipTransitionType.dissolve,
        transitionDuration: Duration(milliseconds: 800),
      );
      final second = first.copyWith(
        clipId: 'second',
        imageFit: VideoTemplateImageFit.contain,
        cropTransform: const ImageCropTransform(
          focalX: 0.6,
          focalY: -0.4,
          zoom: 2,
        ),
        caption: 'Second memory',
        captionSupportingLine: 'Different occurrence',
        motionOverride: ClipMotionPreset.slowZoomIn,
        motionIntensity: ClipMotionIntensity.moreMovement,
        transitionOverride: ClipTransitionType.slide,
        transitionDuration: const Duration(milliseconds: 1200),
      );
      final project = ProjectTimeline(
        id: 'project',
        name: 'Memory',
        audioSourcePath: 'missing-song.mp3',
        beatMap: const BeatMap(
          beats: [],
          bpm: 0,
          averageBeatInterval: Duration(seconds: 1),
        ),
        tracks: [
          TimelineTrack(
            id: 'track-media',
            name: 'Images',
            events: [
              const BeatEvent(
                time: Duration.zero,
                type: 'image',
                payload: first,
              ),
              BeatEvent(
                time: const Duration(seconds: 3),
                type: 'image',
                payload: second,
              ),
            ],
          ),
        ],
      );
      final repository = FileProjectRepository(
        serializer: const ProjectSerializer(),
        supportDirectory: () async => dir,
      );
      await repository.save(project);
      final reopened = (await repository.loadAll()).single;
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          imageFilePickerProvider.overrideWithValue(
            _ImagePicker(replacement.path),
          ),
          audioFilePickerProvider.overrideWithValue(
            _AudioPicker(replacementAudio.path),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(timelineViewModelProvider.future);
      container
          .read(timelineViewModelProvider.notifier)
          .projectOpened(reopened);
      final missing = await container.read(
        missingProjectMediaProvider(reopened).future,
      );
      expect(missing, hasLength(2));
      final missingImage = missing.singleWhere((item) => !item.isAudio);
      final missingAudio = missing.singleWhere((item) => item.isAudio);

      final recovery = container.read(projectMediaRecoveryProvider);
      expect(await recovery.relink(project, missingImage), isTrue);
      var updated = container.read(timelineViewModelProvider).value!.project!;
      final clips = updated.tracks.single.events
          .map((e) => e.payload as MediaTrackClipPayload)
          .toList();
      expect(clips.map((c) => c.sourcePath), [
        replacement.path,
        replacement.path,
      ]);
      expect(clips.map((c) => c.clipId), ['first', 'second']);
      expect(clips.map((c) => c.caption), ['Memory', 'Second memory']);
      expect(clips.map((c) => c.captionSupportingLine), [
        '',
        'Different occurrence',
      ]);
      expect(clips.map((c) => c.imageFit), [
        VideoTemplateImageFit.cover,
        VideoTemplateImageFit.contain,
      ]);
      expect(clips.map((c) => c.cropTransform), [
        const ImageCropTransform(focalX: -0.7, focalY: 0.3, zoom: 1.5),
        const ImageCropTransform(focalX: 0.6, focalY: -0.4, zoom: 2),
      ]);
      expect(clips.map((c) => c.motionOverride), [
        ClipMotionPreset.gentlePan,
        ClipMotionPreset.slowZoomIn,
      ]);
      expect(clips.map((c) => c.motionIntensity), [
        ClipMotionIntensity.subtle,
        ClipMotionIntensity.moreMovement,
      ]);
      expect(clips.map((c) => c.useStyleMotionIntensity), [false, false]);
      expect(clips.map((c) => c.transitionOverride), [
        ClipTransitionType.dissolve,
        ClipTransitionType.slide,
      ]);
      expect(clips.map((c) => c.transitionDuration), [
        const Duration(milliseconds: 800),
        const Duration(milliseconds: 1200),
      ]);

      expect(updated.audioSourcePath, 'missing-song.mp3');
      expect(await recovery.relink(updated, missingAudio), isTrue);
      updated = container.read(timelineViewModelProvider).value!.project!;
      expect(updated.audioSourcePath, replacementAudio.path);
      expect(
        await container.read(missingProjectMediaProvider(updated).future),
        isEmpty,
      );
      await repository.save(updated);
      final reopenedAfterRelink = (await repository.loadAll()).single;
      final persistedClips = reopenedAfterRelink.tracks.single.events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(persistedClips.map((clip) => clip.clipId), ['first', 'second']);
      expect(persistedClips.map((clip) => clip.sourcePath), [
        replacement.path,
        replacement.path,
      ]);
      expect(persistedClips.map((clip) => clip.caption), [
        'Memory',
        'Second memory',
      ]);
      expect(persistedClips.map((clip) => clip.imageFit), [
        VideoTemplateImageFit.cover,
        VideoTemplateImageFit.contain,
      ]);
      expect(persistedClips.map((clip) => clip.cropTransform), [
        const ImageCropTransform(focalX: -0.7, focalY: 0.3, zoom: 1.5),
        const ImageCropTransform(focalX: 0.6, focalY: -0.4, zoom: 2),
      ]);
      expect(persistedClips.map((clip) => clip.captionSupportingLine), [
        '',
        'Different occurrence',
      ]);
      expect(persistedClips.map((clip) => clip.motionOverride), [
        ClipMotionPreset.gentlePan,
        ClipMotionPreset.slowZoomIn,
      ]);
      expect(persistedClips.map((clip) => clip.motionIntensity), [
        ClipMotionIntensity.subtle,
        ClipMotionIntensity.moreMovement,
      ]);
      expect(persistedClips.map((clip) => clip.transitionOverride), [
        ClipTransitionType.dissolve,
        ClipTransitionType.slide,
      ]);
      expect(persistedClips.map((clip) => clip.transitionDuration), [
        const Duration(milliseconds: 800),
        const Duration(milliseconds: 1200),
      ]);
      expect(reopenedAfterRelink.audioSourcePath, replacementAudio.path);
    },
  );
}

class _ImagePicker implements ImageFilePicker {
  _ImagePicker(this.path);
  final String path;

  @override
  Future<List<PickedImageFile>> pickImageFiles() async => [
    PickedImageFile(
      name: 'replacement.jpg',
      extension: 'jpg',
      size: 1,
      path: path,
    ),
  ];
}

class _AudioPicker implements AudioFilePicker {
  _AudioPicker(this.path);
  final String path;

  @override
  Future<PickedAudioFile?> pickAudioFile() async => _pickedFile();

  @override
  Future<PickedAudioFile?> pickSongFile() async => _pickedFile();

  PickedAudioFile _pickedFile() => PickedAudioFile(
    name: 'replacement.mp3',
    extension: 'mp3',
    bytes: Uint8List.fromList([2]),
    byteLength: 1,
    path: path,
  );
}
