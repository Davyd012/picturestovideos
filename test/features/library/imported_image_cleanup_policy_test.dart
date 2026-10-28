import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/imported_image_cleanup_policy.dart';

void main() {
  test('retains removed assets referenced by current or saved projects', () {
    final assets = [
      _asset('/app/imported_images/used.png'),
      _asset('/app/imported_images/currently-used.png'),
      _asset('/app/imported_images/unused.jpg'),
      _asset('/app/imported_images/kept-in-library.webp'),
    ];
    final savedProject = _project('saved', '/app/imported_images/used.png');
    final currentProject = _project(
      'current',
      '/app/imported_images/currently-used.png',
    );

    final cleanupPaths = unusedImportedImagePaths(
      assets: assets,
      removedIds: {
        '/app/imported_images/used.png',
        '/app/imported_images/currently-used.png',
        '/app/imported_images/unused.jpg',
      },
      projects: [savedProject, currentProject],
    );

    expect(cleanupPaths, {'/app/imported_images/unused.jpg'});
  });
}

SavedImageAsset _asset(String path) => SavedImageAsset(
  id: path,
  fileName: path.split('/').last,
  sourcePath: path,
  byteLength: 10,
  importedOn: DateTime(2026),
);

ProjectTimeline _project(String id, String sourcePath) => ProjectTimeline(
  id: id,
  name: id,
  beatMap: const BeatMap(
    beats: [],
    bpm: 0,
    averageBeatInterval: Duration(seconds: 1),
  ),
  tracks: [
    TimelineTrack(
      id: 'media',
      name: 'Media',
      events: [
        BeatEvent(
          time: Duration.zero,
          type: 'image',
          payload: MediaTrackClipPayload(
            mediaId: sourcePath,
            title: 'Photo',
            tagline: '',
            start: Duration.zero,
            end: const Duration(seconds: 2),
            sourcePath: sourcePath,
            imageFit: VideoTemplateImageFit.cover,
          ),
        ),
      ],
    ),
  ],
);
