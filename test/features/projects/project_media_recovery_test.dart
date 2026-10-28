import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/audio_file_picker.dart';
import 'package:picturestovideos/core/audio/data/device_audio_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
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
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
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
      final otherImage = File('${dir.path}/other.jpg');
      await replacement.writeAsBytes([1]);
      await replacementAudio.writeAsBytes([2]);
      await otherImage.writeAsBytes([3]);
      addTearDown(() async {
        await replacement.delete();
        await replacementAudio.delete();
        await otherImage.delete();
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
          beats: [
            Beat(time: Duration(seconds: 1), strength: 1),
            Beat(time: Duration(seconds: 4), strength: 1),
          ],
          bpm: 120,
          averageBeatInterval: Duration(seconds: 2),
        ),
        audioDuration: const Duration(seconds: 12),
        tracks: [
          const TimelineTrack(
            id: 'track-markers',
            name: 'Markers',
            events: [
              BeatEvent(
                time: Duration(seconds: 1),
                type: 'marker',
                payload: 'First beat',
              ),
              BeatEvent(
                time: Duration(seconds: 4),
                type: 'marker',
                payload: 'Second beat',
              ),
            ],
          ),
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
      final reorderedMedia = [
        _mediaItem('other', 'Other', otherImage.path),
        _mediaItem('photo', 'Photo', 'missing.jpg'),
      ];
      const beatMap = BeatMap(
        beats: [
          Beat(time: Duration(seconds: 1), strength: 1),
          Beat(time: Duration(seconds: 4), strength: 1),
        ],
        bpm: 120,
        averageBeatInterval: Duration(seconds: 2),
      );
      const markerEvents = [
        BeatEvent(
          time: Duration(seconds: 1),
          type: 'marker',
          payload: 'First beat',
        ),
        BeatEvent(
          time: Duration(seconds: 4),
          type: 'marker',
          payload: 'Second beat',
        ),
      ];
      final timeline = container.read(timelineViewModelProvider.notifier);
      await timeline.buildProjectTimeline(
        beatMap: beatMap,
        events: markerEvents,
        selectedMedia: reorderedMedia,
        audioDuration: const Duration(seconds: 12),
      );
      var rebuilt = container.read(timelineViewModelProvider).value!.project!;
      var rebuiltClips = rebuilt.tracks
          .singleWhere((track) => track.id == 'track-media')
          .events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(rebuiltClips.map((clip) => clip.mediaId), [
        'other',
        'photo',
        'photo',
      ]);
      expect(rebuiltClips.map((clip) => clip.clipId).skip(1), [
        'first',
        'second',
      ]);
      final balancedStarts = rebuiltClips.map((clip) => clip.start).toList();

      timeline.pacingSelected(SequencePacing.energetic);
      await timeline.applyPacingSuggestion(
        beatMap: beatMap,
        events: markerEvents,
        selectedMedia: reorderedMedia,
        selectedImageFits: const {},
        audioDuration: const Duration(seconds: 12),
      );
      rebuilt = container.read(timelineViewModelProvider).value!.project!;
      rebuiltClips = rebuilt.tracks
          .singleWhere((track) => track.id == 'track-media')
          .events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(rebuilt.pacing, SequencePacing.energetic);
      expect(rebuiltClips.map((clip) => clip.mediaId), [
        'other',
        'photo',
        'photo',
      ]);
      expect(rebuiltClips.map((clip) => clip.clipId).skip(1), [
        'first',
        'second',
      ]);
      expect(rebuiltClips.map((clip) => clip.start), isNot(balancedStarts));
      expect(rebuiltClips[1].cropTransform, first.cropTransform);
      expect(rebuiltClips[2].cropTransform, second.cropTransform);
      await repository.save(rebuilt);
      final reopenedAfterPacing = (await repository.loadAll()).single;
      container
          .read(timelineViewModelProvider.notifier)
          .projectOpened(reopenedAfterPacing);
      final missing = await container.read(
        missingProjectMediaProvider(reopenedAfterPacing).future,
      );
      expect(missing, hasLength(2));
      final missingImage = missing.singleWhere((item) => !item.isAudio);
      final missingAudio = missing.singleWhere((item) => item.isAudio);

      final recovery = container.read(projectMediaRecoveryProvider);
      expect(await recovery.relink(reopenedAfterPacing, missingImage), isTrue);
      var updated = container.read(timelineViewModelProvider).value!.project!;
      final clips = updated.tracks
          .singleWhere((track) => track.id == 'track-media')
          .events
          .map((e) => e.payload as MediaTrackClipPayload)
          .toList();
      expect(clips.first.mediaId, 'other');
      expect(clips.first.sourcePath, otherImage.path);
      final repeatedClips = clips
          .where((clip) => clip.mediaId == 'photo')
          .toList();
      expect(repeatedClips.map((c) => c.sourcePath), [
        replacement.path,
        replacement.path,
      ]);
      expect(repeatedClips.map((c) => c.clipId), ['first', 'second']);
      expect(repeatedClips.map((c) => c.caption), ['Memory', 'Second memory']);
      expect(repeatedClips.map((c) => c.captionSupportingLine), [
        '',
        'Different occurrence',
      ]);
      expect(repeatedClips.map((c) => c.imageFit), [
        VideoTemplateImageFit.cover,
        VideoTemplateImageFit.contain,
      ]);
      expect(repeatedClips.map((c) => c.cropTransform), [
        const ImageCropTransform(focalX: -0.7, focalY: 0.3, zoom: 1.5),
        const ImageCropTransform(focalX: 0.6, focalY: -0.4, zoom: 2),
      ]);
      expect(repeatedClips.map((c) => c.motionOverride), [
        ClipMotionPreset.gentlePan,
        ClipMotionPreset.slowZoomIn,
      ]);
      expect(repeatedClips.map((c) => c.motionIntensity), [
        ClipMotionIntensity.subtle,
        ClipMotionIntensity.moreMovement,
      ]);
      expect(repeatedClips.map((c) => c.useStyleMotionIntensity), [
        false,
        false,
      ]);
      expect(repeatedClips.map((c) => c.transitionOverride), [
        ClipTransitionType.dissolve,
        ClipTransitionType.slide,
      ]);
      expect(repeatedClips.map((c) => c.transitionDuration), [
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
      final persistedClips = reopenedAfterRelink.tracks
          .singleWhere((track) => track.id == 'track-media')
          .events
          .map((event) => event.payload as MediaTrackClipPayload)
          .toList();
      expect(persistedClips.first.mediaId, 'other');
      expect(persistedClips.first.sourcePath, otherImage.path);
      final persistedRepeatedClips = persistedClips
          .where((clip) => clip.mediaId == 'photo')
          .toList();
      expect(persistedRepeatedClips.map((clip) => clip.clipId), [
        'first',
        'second',
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.sourcePath), [
        replacement.path,
        replacement.path,
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.caption), [
        'Memory',
        'Second memory',
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.imageFit), [
        VideoTemplateImageFit.cover,
        VideoTemplateImageFit.contain,
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.cropTransform), [
        const ImageCropTransform(focalX: -0.7, focalY: 0.3, zoom: 1.5),
        const ImageCropTransform(focalX: 0.6, focalY: -0.4, zoom: 2),
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.captionSupportingLine), [
        '',
        'Different occurrence',
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.motionOverride), [
        ClipMotionPreset.gentlePan,
        ClipMotionPreset.slowZoomIn,
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.motionIntensity), [
        ClipMotionIntensity.subtle,
        ClipMotionIntensity.moreMovement,
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.transitionOverride), [
        ClipTransitionType.dissolve,
        ClipTransitionType.slide,
      ]);
      expect(persistedRepeatedClips.map((clip) => clip.transitionDuration), [
        const Duration(milliseconds: 800),
        const Duration(milliseconds: 1200),
      ]);
      expect(reopenedAfterRelink.audioSourcePath, replacementAudio.path);
    },
  );
}

LibraryMediaItem _mediaItem(String id, String title, String sourcePath) =>
    LibraryMediaItem(
      id: id,
      title: title,
      sizeLabel: '1 KB',
      tagline: '',
      importedOnLabel: 'Oct 28, 2026',
      importedOn: DateTime(2026, 10, 28),
      byteLength: 1,
      thumbnailBytes: Uint8List(0),
      sourcePath: sourcePath,
    );

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
