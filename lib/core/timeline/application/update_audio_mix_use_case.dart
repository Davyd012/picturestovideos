import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

class UpdateAudioMixUseCase {
  const UpdateAudioMixUseCase();

  ProjectTimeline call(ProjectTimeline project, AudioMix mix) {
    if (mix.start < Duration.zero ||
        (mix.end != null && mix.end! <= mix.start) ||
        (project.audioDuration != null &&
            (mix.start >= project.audioDuration! ||
                (mix.end != null && mix.end! > project.audioDuration!))) ||
        mix.fadeIn.isNegative ||
        mix.fadeOut.isNegative) {
      throw const FormatException('Invalid music range');
    }
    final shift = project.audioMix.start - mix.start;
    final beatMap = project.beatMap;
    return project.copyWith(
      audioMix: mix,
      hasManualEdits: true,
      beatMap: BeatMap(
        beats: [
          for (final beat in beatMap.beats)
            Beat(time: beat.time + shift, strength: beat.strength),
        ],
        bpm: beatMap.bpm,
        averageBeatInterval: beatMap.averageBeatInterval,
      ),
      tracks: List.unmodifiable([
        for (final track in project.tracks)
          if (track.id != 'track-markers')
            track
          else
            track.copyWith(
              events: List.unmodifiable([
                for (final event in track.events)
                  BeatEvent(
                    time: event.time + shift,
                    type: event.type,
                    payload: event.payload,
                  ),
              ]),
            ),
      ]),
    );
  }
}
