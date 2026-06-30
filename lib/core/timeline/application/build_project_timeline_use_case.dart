import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/application/build_media_track_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
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
    VideoTemplate template = VideoTemplates.cleanMemories,
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
      markerEvents: events,
      template: template,
    );
    if (mediaTrack != null) {
      tracks.add(mediaTrack);
    }

    return ProjectTimeline(
      id: 'project-main',
      name: 'Picture To Videos Project',
      beatMap: beatMap,
      tracks: List.unmodifiable(tracks),
      template: template,
    );
  }
}
