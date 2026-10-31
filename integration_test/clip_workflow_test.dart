import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/move_timeline_clip_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/application/resolve_media_track_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/editor/widgets/clip_caption_list.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '56 clip repeated media selection, crop, reorder, save and reopen',
    (tester) async {
      var project = _project();
      var selectedId = 'clip-1';
      var selectedTime = Duration.zero;
      await tester.binding.setSurfaceSize(const Size(420, 840));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                final clips = const ResolveMediaTrackClipsUseCase().call(
                  beatMap: project.beatMap,
                  project: project,
                );
                return Scaffold(
                  body: Column(
                    children: [
                      Text(
                        'Preview: $selectedId at ${selectedTime.inSeconds}s',
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                project = _updateClip(
                                  project,
                                  selectedId,
                                  (clip) => clip.copyWith(
                                    cropTransform: const ImageCropTransform(
                                      focalX: 0.3,
                                      zoom: 2,
                                    ),
                                  ),
                                );
                              });
                            },
                            child: const Text('Apply crop'),
                          ),
                          TextButton(
                            onPressed: () {
                              const serializer = ProjectSerializer();
                              setState(() {
                                project = serializer.deserialize(
                                  serializer.serialize(project),
                                );
                              });
                            },
                            child: const Text('Save and reopen'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ClipCaptionList(
                          clips: clips,
                          onEdit: (_, _) {},
                          onSelect: (clip) {
                            setState(() {
                              selectedId = clip.clipId;
                              selectedTime =
                                  clip.start + ((clip.end - clip.start) ~/ 2);
                            });
                          },
                          onMove: (id, position) {
                            setState(() {
                              project = const MoveTimelineClipUseCase().call(
                                project,
                                id,
                                position,
                              );
                            });
                            return true;
                          },
                          onReorder: (id, position) {
                            setState(() {
                              project = const MoveTimelineClipUseCase().call(
                                project,
                                id,
                                position,
                              );
                            });
                            return true;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -12000));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Clip 56: Image 56'));
      await tester.tap(find.text('Clip 56: Image 56'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Preview: clip-56'), findsOneWidget);
      expect(selectedTime, const Duration(seconds: 166));

      await tester.tap(find.text('Apply crop'));
      await tester.pumpAndSettle();
      expect(_clipById(project, 'clip-56').cropTransform.zoom, 2);
      expect(
        _clipById(project, 'clip-55').cropTransform,
        ImageCropTransform.centered,
      );

      await tester.tap(find.text('Reorder'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ReorderableListView),
        const Offset(0, -12000),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Clip 56: Image 56'));
      final handle = find.byIcon(Icons.drag_handle).last;
      await tester.drag(handle, const Offset(0, -96));
      await tester.pumpAndSettle();
      final afterMove = const ResolveMediaTrackClipsUseCase().call(
        beatMap: project.beatMap,
        project: project,
      );
      expect(afterMove[54].clipId, 'clip-56');
      expect(afterMove[54].cropTransform.zoom, 2);
      expect(afterMove[55].clipId, 'clip-55');

      await tester.tap(find.text('Save and reopen'));
      await tester.pumpAndSettle();
      final exportInput = const ResolveMediaTrackClipsUseCase().call(
        beatMap: project.beatMap,
        project: project,
      );
      expect(exportInput[54].clipId, 'clip-56');
      expect(exportInput[54].cropTransform.zoom, 2);
      expect(project.hasManualEdits, isTrue);
    },
  );
}

ProjectTimeline _project() {
  final clips = List.generate(56, (index) {
    final id = index + 1;
    final repeated = id >= 55;
    return MediaTrackClipPayload(
      clipId: 'clip-$id',
      mediaId: repeated ? 'repeated-photo' : 'media-$id',
      title: 'Image $id',
      tagline: '',
      start: Duration(seconds: index * 3),
      end: Duration(seconds: index * 3 + 2),
      sourcePath: '',
      imageFit: VideoTemplateImageFit.cover,
      caption: 'Caption $id',
    );
  });
  return ProjectTimeline(
    id: 'clip-workflow',
    name: 'Clip workflow',
    beatMap: const BeatMap(
      beats: [],
      bpm: 0,
      averageBeatInterval: Duration(seconds: 2),
    ),
    tracks: [
      TimelineTrack(
        id: 'track-media',
        name: 'Images',
        events: [
          for (final clip in clips)
            BeatEvent(time: clip.start, type: 'image', payload: clip),
        ],
      ),
    ],
  );
}

ProjectTimeline _updateClip(
  ProjectTimeline project,
  String clipId,
  MediaTrackClipPayload Function(MediaTrackClipPayload clip) update,
) => project.copyWith(
  tracks: [
    for (final track in project.tracks)
      if (track.id == 'track-media')
        track.copyWith(
          events: [
            for (final event in track.events)
              if (event.payload is MediaTrackClipPayload &&
                  (event.payload as MediaTrackClipPayload).clipId == clipId)
                BeatEvent(
                  time: event.time,
                  type: event.type,
                  payload: update(event.payload as MediaTrackClipPayload),
                )
              else
                event,
          ],
        )
      else
        track,
  ],
  hasManualEdits: true,
);

MediaTrackClipPayload _clipById(ProjectTimeline project, String clipId) =>
    project.tracks
        .firstWhere((track) => track.id == 'track-media')
        .events
        .map((event) => event.payload)
        .whereType<MediaTrackClipPayload>()
        .singleWhere((clip) => clip.clipId == clipId);
