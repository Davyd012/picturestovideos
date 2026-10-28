import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_track.dart';
import 'package:picturestovideos/features/library/image_file_picker.dart';
import 'package:picturestovideos/features/library/image_import_repository.dart';
import 'package:picturestovideos/features/projects/project_media_recovery_card.dart';

void main() {
  testWidgets('relink failure is localized and hides picker details', (
    tester,
  ) async {
    final missingPath =
        '${Directory.systemTemp.path}/missing-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final project = ProjectTimeline(
      id: 'recovery-ui',
      name: 'Recovery UI',
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
            BeatEvent(
              time: Duration.zero,
              type: 'image',
              payload: MediaTrackClipPayload(
                clipId: 'missing-photo',
                mediaId: 'photo',
                title: 'Photo',
                tagline: '',
                start: Duration.zero,
                end: const Duration(seconds: 2),
                sourcePath: missingPath,
                imageFit: VideoTemplateImageFit.cover,
                cropTransform: ImageCropTransform.centered,
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageFilePickerProvider.overrideWithValue(_FailingImagePicker()),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ProjectMediaRecoveryCard(project: project)),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Указать файл'), findsOneWidget);
    await tester.tap(find.text('Указать файл'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось открыть выбранный файл.'), findsOneWidget);
    expect(find.textContaining('Picker internals'), findsNothing);
  });
}

class _FailingImagePicker implements ImageFilePicker {
  @override
  Future<List<PickedImageFile>> pickImageFiles() async {
    throw StateError('Picker internals must not appear in the UI');
  }
}
