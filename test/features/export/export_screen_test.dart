import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/data/audio_player_repository.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/event_system/event_system_view_model.dart';
import 'package:picturestovideos/features/export/export_screen.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';

void main() {
  testWidgets('export screen shows blocked state without project data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          renderCapabilitiesProvider.overrideWith(
            (ref) async => _capableRenderer(),
          ),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finalize output'), findsOneWidget);
    expect(find.textContaining('Unavailable'), findsWidgets);
    expect(find.text('Export / Download'), findsAtLeastNWidgets(1));
  });

  testWidgets('export screen shows ready state when timeline data exists', (
    tester,
  ) async {
    final player = ManualAudioPlayerRepository();
    final container = ProviderContainer(
      overrides: [
        audioPlayerRepositoryProvider.overrideWithValue(player),
        renderCapabilitiesProvider.overrideWith(
          (ref) async => _capableRenderer(),
        ),
      ],
    );
    addTearDown(player.dispose);
    addTearDown(container.dispose);

    const beatMap = BeatMap(
      beats: [
        Beat(time: Duration(milliseconds: 200), strength: 1.6),
        Beat(time: Duration(milliseconds: 700), strength: 1.4),
        Beat(time: Duration(milliseconds: 1200), strength: 1.8),
      ],
      bpm: 120,
      averageBeatInterval: Duration(milliseconds: 500),
    );

    await container.read(beatMapViewModelProvider.future);
    await container
        .read(beatMapViewModelProvider.notifier)
        .buildBeatMap(beatMap.beats);

    await container.read(eventSystemViewModelProvider.future);
    await container
        .read(eventSystemViewModelProvider.notifier)
        .loadMarkerEventsFromBeatMap(beatMap);

    await container.read(playbackViewModelProvider.future);
    await container
        .read(playbackViewModelProvider.notifier)
        .loadBeatMap(beatMap);

    await container.read(timelineViewModelProvider.future);
    await container
        .read(timelineViewModelProvider.notifier)
        .buildProjectTimeline(
          beatMap: beatMap,
          events: container.read(eventSystemViewModelProvider).value!.events,
          selectedMedia: [
            LibraryMediaItem(
              id: 'image',
              title: 'Image.jpg',
              sizeLabel: '1 MB',
              tagline: '',
              importedOnLabel: '',
              importedOn: DateTime(2026),
              byteLength: 1024,
              thumbnailBytes: Uint8List(0),
              sourcePath: '/tmp/image.jpg',
            ),
          ],
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Image preview summary'), findsOneWidget);
    expect(find.text('Finalize output'), findsOneWidget);
    expect(find.text('Picture To Videos Project'), findsWidgets);
    expect(find.text('Render'), findsOneWidget);
  });

  testWidgets('export is enabled for manually timed clips without beats', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        renderCapabilitiesProvider.overrideWith(
          (ref) async => _capableRenderer(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(timelineViewModelProvider.future);
    container
        .read(timelineViewModelProvider.notifier)
        .addManualImagePointAt(
          time: const Duration(seconds: 1),
          beatMap: null,
          selectedMedia: [
            LibraryMediaItem(
              id: 'image',
              title: 'Image.jpg',
              sizeLabel: '1 MB',
              tagline: 'Imported image',
              importedOnLabel: 'Jul 14, 2026',
              importedOn: DateTime(2026, 7, 14),
              byteLength: 1024,
              thumbnailBytes: Uint8List(0),
              sourcePath: '/tmp/image.jpg',
            ),
          ],
          audioDuration: const Duration(minutes: 4, seconds: 16),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final exportButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Export').first,
    );
    expect(exportButton.onPressed, isNotNull);
    expect(find.text('Preview unavailable'), findsNothing);
  });

  testWidgets('unsupported motion capability disables export with guidance', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        renderCapabilitiesProvider.overrideWith(
          (ref) async => _capableRenderer(missingZoompan: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(timelineViewModelProvider.future);
    container
        .read(timelineViewModelProvider.notifier)
        .addManualImagePointAt(
          time: const Duration(seconds: 1),
          beatMap: null,
          selectedMedia: [
            LibraryMediaItem(
              id: 'image',
              title: 'Image.jpg',
              sizeLabel: '1 MB',
              tagline: '',
              importedOnLabel: '',
              importedOn: DateTime(2026),
              byteLength: 1024,
              thumbnailBytes: Uint8List(0),
              sourcePath: '/tmp/image.jpg',
            ),
          ],
          audioDuration: null,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final renderButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Render').first,
    );
    expect(renderButton.onPressed, isNull);
    expect(
      find.textContaining('FFmpeg filter that is unavailable'),
      findsOneWidget,
    );
  });
}

RenderCapabilities _capableRenderer({bool missingZoompan = false}) =>
    RenderCapabilities(
      platformSupported: true,
      ffmpegAvailable: true,
      filters: {
        'scale',
        'crop',
        'pad',
        'drawbox',
        'drawtext',
        'xfade',
        if (!missingZoompan) 'zoompan',
        'atrim',
        'asetpts',
        'afade',
        'apad',
      },
      encoders: {'libx264', 'mpeg4', 'aac'},
      muxers: {'mp4'},
      videoEncoder: 'libx264',
      fontPath: 'Arial.ttf',
      version: 'FFmpeg test build',
    );
