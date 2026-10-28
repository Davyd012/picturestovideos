import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';

void main() {
  group('ProjectSerializer', () {
    test('serializes and deserializes project timeline', () {
      const serializer = ProjectSerializer();
      const project = ProjectTimeline(
        id: 'project-main',
        name: 'Picture To Videos Project',
        beatMap: BeatMap(
          beats: [Beat(time: Duration(milliseconds: 200), strength: 1.5)],
          bpm: 120,
          averageBeatInterval: Duration(milliseconds: 500),
        ),
        template: VideoTemplates.cinematicDark,
        tracks: [
          TimelineTrack(
            id: 'track-markers',
            name: 'Markers',
            events: [
              BeatEvent(
                time: Duration(milliseconds: 200),
                type: 'marker',
                payload: 'Beat 1',
              ),
            ],
          ),
        ],
      );

      final json = serializer.serialize(project);
      final deserialized = serializer.deserialize(json);

      expect(deserialized.id, project.id);
      expect(deserialized.tracks.length, 1);
      expect(deserialized.tracks.first.events.first.type, 'marker');
      expect(deserialized.beatMap.bpm, 120);
      expect(deserialized.template.id, VideoTemplates.cinematicDark.id);
      expect(json['schemaVersion'], ProjectSerializer.currentSchemaVersion);
    });

    test('new captions are empty and legacy text migrates', () {
      const clip = MediaTrackClipPayload(
        mediaId: 'photo',
        title: 'photo.jpg',
        tagline: 'Imported',
        start: Duration.zero,
        end: Duration(seconds: 2),
        sourcePath: 'photo.jpg',
        imageFit: VideoTemplateImageFit.cover,
      );
      expect(clip.caption, isEmpty);
      expect(clip.captionSupportingLine, isEmpty);
      final roundTrip = MediaTrackClipPayload.fromJson(clip.toJson());
      expect(roundTrip.caption, isEmpty);
      final legacy = clip.toJson()
        ..remove('caption')
        ..remove('captionSupportingLine');
      final migrated = MediaTrackClipPayload.fromJson(legacy);
      expect(migrated.caption, 'photo.jpg');
      expect(migrated.captionSupportingLine, 'Imported');
      expect(migrated.copyWith(caption: 'Мин летом').caption, 'Мин летом');
    });

    test('rejects unsupported future schema versions', () {
      expect(
        () => const ProjectSerializer().deserialize({'schemaVersion': 999}),
        throwsFormatException,
      );
    });

    test(
      'migrates every supported schema version with stable legacy clips',
      () {
        const serializer = ProjectSerializer();
        const legacyClip = MediaTrackClipPayload(
          mediaId: 'photo',
          title: 'photo.jpg',
          tagline: 'Imported',
          start: Duration.zero,
          end: Duration(seconds: 2),
          sourcePath: 'photo.jpg',
          imageFit: VideoTemplateImageFit.cover,
        );
        final payload = legacyClip.toJson()
          ..remove('clipId')
          ..remove('caption')
          ..remove('captionSupportingLine')
          ..remove('captionSettings')
          ..remove('cropTransform')
          ..remove('motionIntensity')
          ..remove('useStyleMotionIntensity')
          ..remove('transitionOverride')
          ..remove('transitionDurationMs');

        for (
          var version = 0;
          version <= ProjectSerializer.currentSchemaVersion;
          version++
        ) {
          final migrated = serializer.deserialize({
            'schemaVersion': version,
            'id': 'legacy-$version',
            'name': 'Legacy $version',
            'beatMap': {
              'beats': <Object?>[],
              'bpm': 0,
              'averageBeatIntervalMs': 1000,
            },
            'tracks': [
              {
                'id': 'track-media',
                'name': 'Images',
                'events': [
                  {'timeMs': 0, 'type': 'image', 'payload': payload},
                  {'timeMs': 2000, 'type': 'image', 'payload': payload},
                ],
              },
            ],
          });
          final clips = migrated.tracks.single.events
              .map((event) => event.payload as MediaTrackClipPayload)
              .toList();

          expect(clips.map((clip) => clip.clipId), [
            'legacy-0-0',
            'legacy-0-1',
          ], reason: 'schema version $version');
          expect(clips.map((clip) => clip.caption), ['photo.jpg', 'photo.jpg']);
          expect(clips.map((clip) => clip.captionSupportingLine), [
            'Imported',
            'Imported',
          ]);
          expect(clips.every((clip) => clip.cropTransform.isCentered), isTrue);
          expect(
            clips.every(
              (clip) =>
                  clip.transitionOverride ==
                  (version < 5 ? ClipTransitionType.cut : null),
            ),
            isTrue,
            reason: 'schema version $version',
          );

          final reopened = serializer.deserialize(
            serializer.serialize(migrated),
          );
          expect(
            reopened.tracks.single.events.map(
              (event) => (event.payload as MediaTrackClipPayload).clipId,
            ),
            ['legacy-0-0', 'legacy-0-1'],
            reason: 'schema version $version after save/reopen',
          );
          expect(
            reopened.tracks.single.events.map(
              (event) => (event.payload as MediaTrackClipPayload).caption,
            ),
            ['photo.jpg', 'photo.jpg'],
          );
        }
      },
    );

    test('migrates repeated legacy clips to distinct stable identities', () {
      const serializer = ProjectSerializer();
      const clip = MediaTrackClipPayload(
        mediaId: 'photo',
        title: 'photo.jpg',
        tagline: '',
        start: Duration.zero,
        end: Duration(seconds: 2),
        sourcePath: 'photo.jpg',
        imageFit: VideoTemplateImageFit.cover,
      );
      final oldPayload = clip.toJson()
        ..remove('clipId')
        ..remove('caption')
        ..remove('captionSupportingLine')
        ..remove('transitionOverride')
        ..remove('transitionDurationMs');
      final json = <String, Object?>{
        'id': 'old',
        'name': 'Old',
        'beatMap': {
          'beats': <Object?>[],
          'bpm': 0,
          'averageBeatIntervalMs': 1000,
        },
        'tracks': [
          {
            'id': 'track-media',
            'name': 'Images',
            'events': [
              {'timeMs': 0, 'type': 'image', 'payload': oldPayload},
              {'timeMs': 2000, 'type': 'image', 'payload': oldPayload},
            ],
          },
        ],
      };
      final first = serializer.deserialize(json);
      final ids = first.tracks.single.events
          .map((e) => (e.payload as MediaTrackClipPayload).clipId)
          .toList();
      expect(ids.toSet(), hasLength(2));
      expect(
        (first.tracks.single.events.first.payload as MediaTrackClipPayload)
            .transitionOverride,
        ClipTransitionType.cut,
      );
      final restored = serializer.deserialize(serializer.serialize(first));
      expect(
        restored.tracks.single.events.map(
          (e) => (e.payload as MediaTrackClipPayload).clipId,
        ),
        ids,
      );
      expect(
        (restored.tracks.single.events.first.payload as MediaTrackClipPayload)
            .caption,
        'photo.jpg',
      );
    });
  });
}
