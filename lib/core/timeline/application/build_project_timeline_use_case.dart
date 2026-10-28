import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/application/build_media_track_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/clip_id.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

final buildProjectTimelineUseCaseProvider =
    Provider<BuildProjectTimelineUseCase>(
      (ref) => BuildProjectTimelineUseCase(
        ref.watch(buildMediaTrackUseCaseProvider),
      ),
    );

class BuildProjectTimelineUseCase {
  const BuildProjectTimelineUseCase(this._buildMediaTrackUseCase);

  final BuildMediaTrackUseCase _buildMediaTrackUseCase;

  ProjectTimeline call({
    required BeatMap beatMap,
    required List<BeatEvent> events,
    List<LibraryMediaItem> selectedMedia = const [],
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
    VideoTemplate template = VideoTemplates.cleanMemories,
    ProjectTimeline? previousProject,
    Duration? audioDuration,
    SequencePacing? pacing,
  }) {
    final tracks = <TimelineTrack>[
      TimelineTrack(
        id: 'track-markers',
        name: 'Markers',
        events: List.unmodifiable(events),
      ),
    ];
    final mediaTrack = _buildMediaTrackUseCase(
      beatMap: beatMap,
      selectedMedia: selectedMedia,
      selectedImageFits: selectedImageFits,
      selectedCropTransforms: selectedCropTransforms,
      markerEvents: events,
      template: template,
      audioDuration: _musicRangeDuration(
        audioDuration ?? previousProject?.audioDuration,
        previousProject?.audioMix,
      ),
      pacing: pacing ?? previousProject?.pacing ?? SequencePacing.balanced,
      previousClips: [
        for (final track in previousProject?.tracks ?? <TimelineTrack>[])
          if (track.id == 'track-media')
            for (final event in track.events)
              if (event.payload is MediaTrackClipPayload)
                event.payload as MediaTrackClipPayload,
      ],
    );
    if (mediaTrack != null) {
      tracks.add(mediaTrack);
    }
    for (final track in previousProject?.tracks ?? <TimelineTrack>[]) {
      if (track.id != 'track-markers' && track.id != 'track-media') {
        tracks.add(track);
      }
    }

    return ProjectTimeline(
      id: previousProject?.id ?? newClipId(),
      name: previousProject?.name ?? 'Picture To Videos Project',
      audioSourcePath: previousProject?.audioSourcePath,
      audioDuration: audioDuration ?? previousProject?.audioDuration,
      pacing: pacing ?? previousProject?.pacing ?? SequencePacing.balanced,
      hasManualEdits: previousProject?.hasManualEdits ?? false,
      snapToMarkers: previousProject?.snapToMarkers ?? true,
      audioMix: previousProject?.audioMix ?? const AudioMix(),
      beatMap: beatMap,
      tracks: List.unmodifiable(tracks),
      template: template,
    );
  }
}

Duration? _musicRangeDuration(Duration? sourceDuration, AudioMix? mix) {
  if (mix == null) return sourceDuration;
  final end = mix.end ?? sourceDuration;
  if (end == null) return null;
  final duration = end - mix.start;
  return duration > Duration.zero ? duration : null;
}
