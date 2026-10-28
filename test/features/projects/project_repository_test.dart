import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/project_repository.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/projects/saved_projects_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';

void main() {
  test(
    'reopening restores timeline and queue without rebuilding occurrences',
    () async {
      SharedPreferences.setMockInitialValues({});
      const repo = SharedPreferencesProjectRepository(ProjectSerializer());
      const clip = MediaTrackClipPayload(
        clipId: 'one',
        mediaId: 'photo',
        title: 'a.jpg',
        tagline: '',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: 'photo.jpg',
        imageFit: VideoTemplateImageFit.cover,
        caption: 'Memory',
      );
      final project = ProjectTimeline(
        id: 'id',
        name: 'Memory',
        audioSourcePath: 'song.wav',
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
                payload: clip,
              ),
              BeatEvent(
                time: const Duration(seconds: 3),
                type: 'image',
                payload: clip.copyWith(clipId: 'two'),
              ),
            ],
          ),
        ],
      );
      await repo.save(project);
      final player = ManualAudioPlayerRepository();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repo),
          audioPlayerRepositoryProvider.overrideWithValue(player),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(player.dispose);
      final saved = await container.read(savedProjectsViewModelProvider.future);
      await container
          .read(savedProjectsViewModelProvider.notifier)
          .open(saved.single);
      final opened = container.read(timelineViewModelProvider).value!.project!;
      expect(opened.audioSourcePath, 'song.wav');
      expect(
        opened.tracks.single.events.map(
          (e) => (e.payload as MediaTrackClipPayload).clipId,
        ),
        ['one', 'two'],
      );
      expect(
        container
            .read(editorMediaSelectionViewModelProvider)
            .selectedMedia
            .single
            .id,
        'photo',
      );
    },
  );
  test('saves, reopens and replaces projects by identity', () async {
    SharedPreferences.setMockInitialValues({});
    const repo = SharedPreferencesProjectRepository(ProjectSerializer());
    const clip = MediaTrackClipPayload(
      clipId: 'one',
      mediaId: 'photo',
      title: 'a.jpg',
      tagline: '',
      start: Duration.zero,
      end: Duration(seconds: 3),
      sourcePath: 'photo.jpg',
      imageFit: VideoTemplateImageFit.cover,
      caption: 'Мин лето',
      motionOverride: ClipMotionPreset.gentlePan,
    );
    const project = ProjectTimeline(
      id: 'id',
      name: 'Memory',
      audioSourcePath: 'song.wav',
      beatMap: BeatMap(
        beats: [],
        bpm: 0,
        averageBeatInterval: Duration(seconds: 1),
      ),
      tracks: [
        TimelineTrack(
          id: 'track-media',
          name: 'Images',
          events: [
            BeatEvent(time: Duration.zero, type: 'image', payload: clip),
          ],
        ),
      ],
    );
    await repo.save(project);
    await repo.save(project.copyWith(name: 'Updated'));
    final saved = await repo.loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Updated');
    expect(saved.single.audioSourcePath, 'song.wav');
    final restored =
        saved.single.tracks.single.events.single.payload
            as MediaTrackClipPayload;
    expect(restored.clipId, 'one');
    expect(restored.caption, 'Мин лето');
    expect(restored.motionOverride, ClipMotionPreset.gentlePan);
  });
}
