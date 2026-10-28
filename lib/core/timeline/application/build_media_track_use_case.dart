import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/clip_id.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/core/timeline/application/suggest_clip_boundaries_use_case.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

final buildMediaTrackUseCaseProvider = Provider<BuildMediaTrackUseCase>(
  (ref) => const BuildMediaTrackUseCase(),
);

class BuildMediaTrackUseCase {
  const BuildMediaTrackUseCase();

  TimelineTrack? call({
    required BeatMap beatMap,
    required List<LibraryMediaItem> selectedMedia,
    required List<BeatEvent> markerEvents,
    Map<String, VideoTemplateImageFit> selectedImageFits = const {},
    Map<String, ImageCropTransform> selectedCropTransforms = const {},
    VideoTemplate template = VideoTemplates.cleanMemories,
    List<MediaTrackClipPayload> previousClips = const [],
    SequencePacing pacing = SequencePacing.balanced,
    Duration? audioDuration,
  }) {
    if (selectedMedia.isEmpty) {
      return null;
    }

    final events = <BeatEvent>[];
    final available = <String, List<MediaTrackClipPayload>>{};
    for (final clip in previousClips) {
      available.putIfAbsent(clip.mediaId, () => []).add(clip);
    }
    final sequence = <LibraryMediaItem>[
      for (final item in selectedMedia)
        for (
          var i = 0;
          i < (available[item.id]?.length ?? 0).clamp(1, 1 << 30);
          i++
        )
          item,
    ];
    final boundaries = const SuggestClipBoundariesUseCase().call(
      photoCount: sequence.length,
      beatMap: beatMap,
      markers: markerEvents,
      pacing: pacing,
      audioDuration: audioDuration,
    );

    for (var index = 0; index < sequence.length; index++) {
      final item = sequence[index];
      final matches = available[item.id];
      final previous = matches != null && matches.isNotEmpty
          ? matches.removeAt(0)
          : null;
      final start = boundaries[index];
      final end = boundaries[index + 1];

      events.add(
        BeatEvent(
          time: start,
          type: 'image',
          payload:
              previous?.copyWith(
                start: start,
                end: end,
                title: item.title,
                tagline: item.tagline,
                sourcePath: item.sourcePath,
              ) ??
              MediaTrackClipPayload(
                clipId: newClipId(),
                mediaId: item.id,
                title: item.title,
                tagline: item.tagline,
                start: start,
                end: end,
                sourcePath: item.sourcePath,
                imageFit: selectedImageFits[item.id] ?? template.imageFit,
                cropTransform:
                    selectedCropTransforms[item.id] ??
                    ImageCropTransform.centered,
              ),
        ),
      );
    }

    return TimelineTrack(
      id: 'track-media',
      name: 'Images',
      events: List.unmodifiable(events),
    );
  }
}
