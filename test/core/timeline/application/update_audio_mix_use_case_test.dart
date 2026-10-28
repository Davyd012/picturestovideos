import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/update_audio_mix_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  test(
    'changing start shifts markers, restoring start restores their positions',
    () {
      const project = ProjectTimeline(
        id: 'p',
        name: 'P',
        audioDuration: Duration(seconds: 10),
        beatMap: BeatMap(
          beats: [Beat(time: Duration(seconds: 1), strength: 1)],
          bpm: 100,
          averageBeatInterval: Duration(seconds: 1),
        ),
        tracks: [
          TimelineTrack(
            id: 'track-markers',
            name: 'Markers',
            events: [BeatEvent(time: Duration(seconds: 1), type: 'marker')],
          ),
        ],
      );
      const update = UpdateAudioMixUseCase();
      final shifted = update(
        project,
        const AudioMix(
          start: Duration(seconds: 2),
          end: Duration(seconds: 7),
          fadeIn: Duration(seconds: 1),
        ),
      );
      expect(shifted.beatMap.beats.single.time, const Duration(seconds: -1));
      expect(
        shifted.tracks.single.events.single.time,
        const Duration(seconds: -1),
      );
      final restored = const ProjectSerializer().deserialize(
        const ProjectSerializer().serialize(shifted),
      );
      expect(restored.audioMix.start, const Duration(seconds: 2));
      expect(restored.audioMix.fadeIn, const Duration(seconds: 1));
      final reset = update(restored, const AudioMix());
      expect(
        reset.tracks.single.events.single.time,
        const Duration(seconds: 1),
      );
      expect(reset.beatMap.beats.single.time, const Duration(seconds: 1));
      expect(
        () => update(
          project,
          const AudioMix(
            start: Duration(seconds: 9),
            end: Duration(seconds: 11),
          ),
        ),
        throwsFormatException,
      );
    },
  );
}
