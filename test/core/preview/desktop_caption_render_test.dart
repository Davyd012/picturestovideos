import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository_factory_io.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

Future<Set<String>> _renderTemporaryDirectories() async =>
    (await Directory.systemTemp.list().toList())
        .whereType<Directory>()
        .where((entry) => entry.path.contains('picturestovideos-preview-'))
        .map((entry) => entry.path)
        .toSet();

void main() {
  test(
    'source replacement at the same path invalidates rendered preview and cache',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'source-cache-invalidation-test-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final source = File('${directory.path}/same-source.ppm');
      final cacheDirectory = Directory(
        '${Directory.systemTemp.path}/picturestovideos-preview-cache',
      );
      final fixedTimestamp = DateTime(2024, 2, 3, 4, 5, 6);

      Future<Set<String>> cachedSegments() async {
        if (!await cacheDirectory.exists()) return {};
        return (await cacheDirectory.list().toList())
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp4'))
            .map((file) => file.path)
            .toSet();
      }

      Future<void> writeSolidPpm(List<int> rgb) async {
        await source.writeAsBytes([
          ...'P6\n2 2\n255\n'.codeUnits,
          ...List<int>.generate(
            4 * rgb.length,
            (index) => rgb[index % rgb.length],
          ),
        ]);
        await source.setLastModified(fixedTimestamp);
      }

      await writeSolidPpm([240, 20, 20]);
      final originalStat = await source.stat();
      const request = BuildPreviewVideoRequest(
        projectId: 'same-path-source-replacement',
        audioSourcePath: null,
        width: 320,
        height: 180,
        frameRate: 10,
        clips: [
          MediaTrackClipPayload(
            clipId: 'one',
            mediaId: 'same-media',
            title: '',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 1),
            sourcePath: '',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
          ),
        ],
      );
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );

      Future<BuildPreviewVideoResult> render() => renderer.buildPreviewVideo(
        BuildPreviewVideoRequest(
          projectId: request.projectId,
          audioSourcePath: request.audioSourcePath,
          width: request.width,
          height: request.height,
          frameRate: request.frameRate,
          clips: [request.clips.single.copyWith(sourcePath: source.path)],
        ),
      );

      Future<String> firstFrameHash(String path) async {
        final frame = await Process.run('ffmpeg', [
          '-v',
          'error',
          '-i',
          path,
          '-frames:v',
          '1',
          '-f',
          'md5',
          '-',
        ]);
        expect(frame.exitCode, 0, reason: frame.stderr.toString());
        return frame.stdout.toString();
      }

      final first = await render();
      final firstFrame = await firstFrameHash(first.outputPath);
      final cacheAfterFirst = await cachedSegments();
      await writeSolidPpm([20, 20, 240]);
      final replacedStat = await source.stat();
      expect(replacedStat.size, originalStat.size);
      expect(replacedStat.modified, originalStat.modified);

      final second = await render();
      expect(second.signature, isNot(first.signature));
      final secondFrame = await firstFrameHash(second.outputPath);
      expect(secondFrame, isNot(firstFrame));
      final newCacheSegments = (await cachedSegments()).difference(
        cacheAfterFirst,
      );
      expect(newCacheSegments, hasLength(1));
      final corruptedSegment = File(newCacheSegments.single);
      await corruptedSegment.writeAsBytes([1, 2, 3]);

      final recovered = await render();
      expect(recovered.signature, second.signature);
      expect(await firstFrameHash(recovered.outputPath), secondFrame);

      for (final result in [first, second, recovered]) {
        final outputDirectory = File(result.outputPath).parent;
        if (await outputDirectory.exists()) {
          await outputDirectory.delete(recursive: true);
        }
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test('pre-cancelled desktop render starts no render work', () async {
    final before = await _renderTemporaryDirectories();
    final cancellation = RenderCancellation()..cancel();
    final renderer = DesktopPreviewRendererRepository(
      logger: AppLogger(appTalker),
    );

    await expectLater(
      renderer.buildPreviewVideo(
        const BuildPreviewVideoRequest(
          projectId: 'pre-cancelled-render',
          audioSourcePath: null,
          width: 320,
          height: 180,
          frameRate: 10,
          clips: [
            MediaTrackClipPayload(
              clipId: 'pre-cancelled',
              mediaId: 'pre-cancelled',
              title: '',
              tagline: '',
              start: Duration.zero,
              end: Duration(seconds: 1),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
              motionOverride: ClipMotionPreset.none,
            ),
          ],
        ),
        cancellation: cancellation,
      ),
      throwsA(isA<RenderCancelled>()),
    );
    expect(await _renderTemporaryDirectories(), before);
  }, skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS));
  test(
    'concurrent renders share one verified segment cache artifact',
    () async {
      final cacheDirectory = Directory(
        '${Directory.systemTemp.path}/picturestovideos-preview-cache',
      );
      Future<Set<String>> cacheSegments() async {
        if (!await cacheDirectory.exists()) return {};
        return (await cacheDirectory.list().toList())
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp4'))
            .map((file) => file.path)
            .toSet();
      }

      final before = await cacheSegments();
      final uniqueId = DateTime.now().microsecondsSinceEpoch;
      final request = BuildPreviewVideoRequest(
        projectId: 'concurrent-render-cache-$uniqueId',
        audioSourcePath: null,
        width: 640,
        height: 360,
        frameRate: 30,
        clips: [
          MediaTrackClipPayload(
            clipId: 'concurrent-cache-clip-$uniqueId',
            mediaId: 'concurrent-cache-media-$uniqueId',
            title: '',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 3),
            sourcePath: 'lib/assets/icon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
          ),
        ],
      );
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );

      final results = await Future.wait([
        renderer.buildPreviewVideo(request),
        renderer.buildPreviewVideo(request),
      ]);

      expect(results[0].signature, results[1].signature);
      expect(await File(results[0].outputPath).length(), greaterThan(0));
      expect(await File(results[1].outputPath).length(), greaterThan(0));
      expect((await cacheSegments()).difference(before), hasLength(1));
      for (final result in results) {
        await File(result.outputPath).parent.delete(recursive: true);
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'cancelled desktop render cleans its temporary directory',
    () async {
      final before = await _renderTemporaryDirectories();
      final cancellation = RenderCancellation();
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      var previousOverallProgress = 0.0;
      var cancelledDuringSegment = false;
      final uniqueId = DateTime.now().microsecondsSinceEpoch;
      final request = BuildPreviewVideoRequest(
        projectId: 'cancel-render-integration-$uniqueId',
        audioSourcePath: null,
        width: 640,
        height: 360,
        frameRate: 30,
        clips: [
          MediaTrackClipPayload(
            clipId: 'cancel',
            mediaId: 'cancel-test-$uniqueId',
            title: '',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 8),
            sourcePath: 'lib/assets/icon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.slowZoomIn,
          ),
        ],
      );
      await expectLater(
        renderer.buildPreviewVideo(
          request,
          cancellation: cancellation,
          onProgress: (progress) {
            final overall =
                progress.completedSteps + progress.currentStepProgress;
            expect(progress.totalSteps, greaterThan(0));
            expect(progress.currentStepProgress, inInclusiveRange(0, 1));
            expect(overall, inInclusiveRange(0, progress.totalSteps));
            expect(overall, greaterThanOrEqualTo(previousOverallProgress));
            previousOverallProgress = overall;
            if (progress.currentStepLabel.startsWith('Rendering clip') &&
                progress.currentStepProgress > 0) {
              cancelledDuringSegment = true;
              cancellation.cancel();
            }
          },
        ),
        throwsA(isA<RenderCancelled>()),
      );
      expect(cancelledDuringSegment, isTrue);
      expect((await _renderTemporaryDirectories()).difference(before), isEmpty);
      cancellation.cancel();

      final restarted = await renderer.buildPreviewVideo(request);
      expect(await File(restarted.outputPath).length(), greaterThan(0));
      await File(restarted.outputPath).parent.delete(recursive: true);
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'cancellation during audio/video finalization cleans up and permits restart',
    () async {
      final before = await _renderTemporaryDirectories();
      final audioDirectory = await Directory.systemTemp.createTemp(
        'render-cancel-audio-test-',
      );
      addTearDown(() async {
        if (await audioDirectory.exists()) {
          await audioDirectory.delete(recursive: true);
        }
      });
      final audioPath = '${audioDirectory.path}/music.wav';
      final audioGeneration = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=8:sample_rate=8000',
        '-c:a',
        'pcm_s16le',
        audioPath,
      ]);
      expect(audioGeneration.exitCode, 0, reason: audioGeneration.stderr);

      const request = BuildPreviewVideoRequest(
        projectId: 'cancel-finalization-audio',
        audioSourcePath: null,
        width: 640,
        height: 360,
        frameRate: 30,
        clips: [
          MediaTrackClipPayload(
            clipId: 'cancel-audio-first',
            mediaId: 'first',
            title: '',
            tagline: '',
            start: Duration.zero,
            end: Duration(seconds: 4),
            sourcePath: 'lib/assets/icon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
            transitionOverride: ClipTransitionType.dissolve,
            transitionDuration: Duration(milliseconds: 600),
          ),
          MediaTrackClipPayload(
            clipId: 'cancel-audio-second',
            mediaId: 'second',
            title: '',
            tagline: '',
            start: Duration(seconds: 4),
            end: Duration(seconds: 8),
            sourcePath: 'web/favicon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
          ),
        ],
      );
      BuildPreviewVideoRequest withAudio() => BuildPreviewVideoRequest(
        projectId: request.projectId,
        clips: request.clips,
        audioSourcePath: audioPath,
        audioSourceDuration: const Duration(seconds: 8),
        width: request.width,
        height: request.height,
        frameRate: request.frameRate,
      );
      final renderRequest = withAudio();
      final cancellation = RenderCancellation();
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      var previousOverallProgress = 0.0;
      var cancelledDuringFinalization = false;

      await expectLater(
        renderer.buildPreviewVideo(
          renderRequest,
          cancellation: cancellation,
          onProgress: (progress) {
            final overall =
                progress.completedSteps + progress.currentStepProgress;
            expect(progress.totalSteps, greaterThan(0));
            expect(progress.currentStepProgress, inInclusiveRange(0, 1));
            expect(overall, inInclusiveRange(0, progress.totalSteps));
            expect(overall, greaterThanOrEqualTo(previousOverallProgress));
            previousOverallProgress = overall;
            if (progress.currentStepLabel == 'Combining video and audio' &&
                progress.currentStepProgress > 0) {
              cancelledDuringFinalization = true;
              cancellation.cancel();
            }
          },
        ),
        throwsA(isA<RenderCancelled>()),
      );
      expect(cancelledDuringFinalization, isTrue);
      expect((await _renderTemporaryDirectories()).difference(before), isEmpty);
      cancellation.cancel();

      final restarted = await renderer.buildPreviewVideo(renderRequest);
      expect(await File(restarted.outputPath).length(), greaterThan(0));
      await File(restarted.outputPath).parent.delete(recursive: true);
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'caption entrances render only in their chosen portion',
    () async {
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      for (final entrance in [CaptionEntrance.fade, CaptionEntrance.slide]) {
        final clip = MediaTrackClipPayload(
          clipId: 'one',
          mediaId: 'photo',
          title: '',
          tagline: '',
          start: Duration.zero,
          end: const Duration(seconds: 2),
          sourcePath: 'lib/assets/icon.png',
          imageFit: VideoTemplateImageFit.cover,
          motionOverride: ClipMotionPreset.none,
          caption: 'Norge — Привет!',
          captionSettings: CaptionSettings(
            placement: CaptionPlacement.top,
            entrance: entrance,
            startFraction: 0.25,
            endFraction: 0.75,
          ),
        );
        final result = await renderer.buildPreviewVideo(
          BuildPreviewVideoRequest(
            projectId: 'caption-${entrance.name}',
            clips: [clip],
            audioSourcePath: null,
            width: 320,
            height: 180,
            frameRate: 10,
          ),
        );
        Future<Uint8List> frame(String time) async {
          final output = await Process.run('ffmpeg', [
            '-v',
            'error',
            '-ss',
            time,
            '-i',
            result.outputPath,
            '-frames:v',
            '1',
            '-pix_fmt',
            'rgb24',
            '-f',
            'rawvideo',
            '-',
          ], stdoutEncoding: null);
          expect(output.exitCode, 0, reason: output.stderr.toString());
          return Uint8List.fromList(output.stdout as List<int>);
        }

        double diff(Uint8List a, Uint8List b) {
          var sum = 0;
          for (var i = 0; i < a.length; i++) {
            sum += (a[i] - b[i]).abs();
          }
          return sum / a.length;
        }

        final before = await frame('0.2');
        final middle = await frame('1.0');
        final after = await frame('1.8');
        expect(diff(before, middle), greaterThan(2), reason: entrance.name);
        expect(
          diff(before, after),
          lessThan(diff(before, middle) / 2),
          reason: entrance.name,
        );
        final dir = File(result.outputPath).parent;
        for (final entry in await dir.list().toList()) {
          if (entry is File) await entry.delete();
        }
        await dir.delete();
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'music is trimmed, faded and padded to video length',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'picturestovideos-audio-test-',
      );
      final source = '${dir.path}/source.wav';
      final generate = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=1:sample_rate=8000',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=880:duration=1:sample_rate=8000',
        '-filter_complex',
        '[0:a][1:a]concat=n=2:v=0:a=1[a]',
        '-map',
        '[a]',
        '-c:a',
        'pcm_s16le',
        source,
      ]);
      expect(generate.exitCode, 0, reason: generate.stderr.toString());
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      final result = await renderer.buildPreviewVideo(
        BuildPreviewVideoRequest(
          projectId: 'audio-mix',
          audioSourcePath: source,
          audioSourceDuration: const Duration(seconds: 2),
          audioMix: const AudioMix(
            start: Duration(seconds: 1),
            end: Duration(seconds: 2),
            fadeIn: Duration(milliseconds: 200),
            fadeOut: Duration(milliseconds: 200),
          ),
          width: 320,
          height: 180,
          frameRate: 10,
          clips: const [
            MediaTrackClipPayload(
              clipId: 'one',
              mediaId: 'one',
              title: '',
              tagline: '',
              start: Duration.zero,
              end: Duration(seconds: 2),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
              motionOverride: ClipMotionPreset.none,
            ),
          ],
        ),
      );
      final decoded = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-i',
        result.outputPath,
        '-map',
        '0:a:0',
        '-ac',
        '1',
        '-ar',
        '8000',
        '-f',
        's16le',
        '-',
      ], stdoutEncoding: null);
      expect(decoded.exitCode, 0, reason: decoded.stderr.toString());
      final bytes = Uint8List.fromList((decoded.stdout as List<int>));
      final samples = ByteData.sublistView(bytes);
      double rms(double from, double to) {
        var sum = 0.0;
        final start = (from * 8000).round();
        final end = (to * 8000).round();
        for (var i = start; i < end; i++) {
          final value = samples.getInt16(i * 2, Endian.little).toDouble();
          sum += value * value;
        }
        return math.sqrt(sum / (end - start));
      }

      expect(rms(0, 0.05), lessThan(rms(0.4, 0.6) * 0.3));
      expect(rms(0.95, 0.99), lessThan(rms(0.4, 0.6) * 0.5));
      expect(rms(1.2, 1.5), lessThan(rms(0.4, 0.6) * 0.02));
      var crossings = 0;
      for (var i = 3201; i < 4000; i++) {
        if (samples.getInt16((i - 1) * 2, Endian.little) < 0 &&
            samples.getInt16(i * 2, Endian.little) >= 0) {
          crossings++;
        }
      }
      expect(crossings, inInclusiveRange(85, 91));
      for (final entry in await File(
        result.outputPath,
      ).parent.list().toList()) {
        if (entry is File) await entry.delete();
      }
      await File(result.outputPath).parent.delete();
      await File(source).delete();
      await dir.delete();
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'mixed cuts and transitions preserve the initial offset and total length',
    () async {
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      final result = await renderer.buildPreviewVideo(
        const BuildPreviewVideoRequest(
          projectId: 'mixed-boundaries',
          audioSourcePath: null,
          width: 320,
          height: 180,
          frameRate: 10,
          clips: [
            MediaTrackClipPayload(
              clipId: 'one',
              mediaId: 'one',
              title: '',
              tagline: '',
              start: Duration(milliseconds: 500),
              end: Duration(milliseconds: 1500),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
              motionOverride: ClipMotionPreset.none,
              transitionOverride: ClipTransitionType.cut,
            ),
            MediaTrackClipPayload(
              clipId: 'two',
              mediaId: 'two',
              title: '',
              tagline: '',
              start: Duration(milliseconds: 1500),
              end: Duration(milliseconds: 2500),
              sourcePath: 'web/favicon.png',
              imageFit: VideoTemplateImageFit.contain,
              motionOverride: ClipMotionPreset.none,
              transitionOverride: ClipTransitionType.dissolve,
              transitionDuration: Duration(milliseconds: 400),
            ),
            MediaTrackClipPayload(
              clipId: 'three',
              mediaId: 'one',
              title: '',
              tagline: '',
              start: Duration(milliseconds: 2500),
              end: Duration(milliseconds: 3500),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
              motionOverride: ClipMotionPreset.none,
            ),
          ],
        ),
      );
      final probe = await Process.run('ffprobe', [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        result.outputPath,
      ]);
      expect(probe.exitCode, 0, reason: probe.stderr.toString());
      expect(double.parse(probe.stdout.toString().trim()), closeTo(3.5, 0.11));
      final dir = File(result.outputPath).parent;
      for (final entry in await dir.list().toList()) {
        if (entry is File) await entry.delete();
      }
      await dir.delete();
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'transitions render across fixed boundaries without shortening the video',
    () async {
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      for (final type in [
        ClipTransitionType.dissolve,
        ClipTransitionType.slide,
      ]) {
        final clips = [
          MediaTrackClipPayload(
            clipId: 'first',
            mediaId: 'one',
            title: '',
            tagline: '',
            start: Duration.zero,
            end: const Duration(seconds: 2),
            sourcePath: 'lib/assets/icon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
            transitionOverride: type,
            transitionDuration: const Duration(milliseconds: 800),
          ),
          const MediaTrackClipPayload(
            clipId: 'second',
            mediaId: 'two',
            title: '',
            tagline: '',
            start: Duration(seconds: 2),
            end: Duration(seconds: 4),
            sourcePath: 'web/favicon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
          ),
        ];
        final result = await renderer.buildPreviewVideo(
          BuildPreviewVideoRequest(
            projectId: 'transition-${type.name}',
            clips: clips,
            audioSourcePath: null,
            width: 320,
            height: 180,
            frameRate: 10,
          ),
        );
        final probe = await Process.run('ffprobe', [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          result.outputPath,
        ]);
        expect(probe.exitCode, 0, reason: probe.stderr.toString());
        expect(double.parse(probe.stdout.toString().trim()), closeTo(4, 0.11));
        Future<String> hashAt(String time) async {
          final frame = await Process.run('ffmpeg', [
            '-v',
            'error',
            '-ss',
            time,
            '-i',
            result.outputPath,
            '-frames:v',
            '1',
            '-f',
            'md5',
            '-',
          ]);
          expect(frame.exitCode, 0, reason: frame.stderr.toString());
          return frame.stdout.toString();
        }

        final before = await hashAt('1.4');
        final middle = await hashAt('2.0');
        final after = await hashAt('2.6');
        expect(middle, isNot(before), reason: type.name);
        expect(middle, isNot(after), reason: type.name);
        final dir = File(result.outputPath).parent;
        for (final entry in await dir.list().toList()) {
          if (entry is File) await entry.delete();
        }
        await dir.delete();
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'desktop renderer produces changing frames for each movement',
    () async {
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      for (final motion in [
        ClipMotionPreset.slowZoomIn,
        ClipMotionPreset.slowZoomOut,
        ClipMotionPreset.gentlePan,
      ]) {
        final clip = MediaTrackClipPayload(
          clipId: 'clip',
          mediaId: 'photo',
          title: '',
          tagline: '',
          start: Duration.zero,
          end: const Duration(seconds: 1),
          sourcePath: 'lib/assets/icon.png',
          imageFit: VideoTemplateImageFit.cover,
          motionOverride: motion,
          motionIntensity: ClipMotionIntensity.moreMovement,
          useStyleMotionIntensity: false,
        );
        final result = await renderer.buildPreviewVideo(
          BuildPreviewVideoRequest(
            projectId: 'motion-${motion.name}',
            clips: [clip],
            audioSourcePath: null,
            width: 320,
            height: 180,
            frameRate: 10,
          ),
        );
        Future<String> hashAt(String time) async {
          final frame = await Process.run('ffmpeg', [
            '-v',
            'error',
            '-ss',
            time,
            '-i',
            result.outputPath,
            '-frames:v',
            '1',
            '-f',
            'md5',
            '-',
          ]);
          expect(frame.exitCode, 0, reason: frame.stderr.toString());
          return frame.stdout.toString();
        }

        expect(
          await hashAt('0'),
          isNot(await hashAt('0.8')),
          reason: motion.name,
        );
        final dir = File(result.outputPath).parent;
        for (final entry in await dir.list().toList()) {
          if (entry is File) await entry.delete();
        }
        await dir.delete();
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
  test(
    'desktop renderer treats Unicode and FFmpeg syntax as literal caption text',
    () async {
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      final result = await renderer.buildPreviewVideo(
        const BuildPreviewVideoRequest(
          projectId: 'caption-integration',
          clips: [
            MediaTrackClipPayload(
              clipId: 'first',
              mediaId: 'photo',
              title: 'Photo',
              tagline: '',
              start: Duration.zero,
              end: Duration(seconds: 1),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
              caption: "Sommer: 'Привет' %{not_a_filter}\n100% [test]",
              captionSupportingLine: 'Æøå — мир',
            ),
          ],
          audioSourcePath: null,
          width: 320,
          height: 180,
          frameRate: 10,
        ),
      );
      expect(await File(result.outputPath).length(), greaterThan(0));
      final plain = await renderer.buildPreviewVideo(
        const BuildPreviewVideoRequest(
          projectId: 'caption-integration-plain',
          clips: [
            MediaTrackClipPayload(
              clipId: 'first',
              mediaId: 'photo',
              title: 'Photo',
              tagline: '',
              start: Duration.zero,
              end: Duration(seconds: 1),
              sourcePath: 'lib/assets/icon.png',
              imageFit: VideoTemplateImageFit.cover,
            ),
          ],
          audioSourcePath: null,
          width: 320,
          height: 180,
          frameRate: 10,
        ),
      );
      Future<String> firstFrameHash(String path) async {
        final frame = await Process.run('ffmpeg', [
          '-v',
          'error',
          '-i',
          path,
          '-frames:v',
          '1',
          '-f',
          'md5',
          '-',
        ]);
        expect(frame.exitCode, 0, reason: frame.stderr.toString());
        return frame.stdout.toString();
      }

      expect(
        await firstFrameHash(result.outputPath),
        isNot(await firstFrameHash(plain.outputPath)),
      );
      final files = await File(result.outputPath).parent.list().toList();
      expect(
        files.whereType<File>().where(
          (f) => f.path.endsWith('.txt') && f.path.contains('caption_'),
        ),
        isEmpty,
      );
      for (final path in [result.outputPath, plain.outputPath]) {
        final directory = File(path).parent;
        for (final entry in await directory.list().toList()) {
          if (entry is File) await entry.delete();
        }
        await directory.delete();
      }
    },
    skip:
        Platform.environment['RUN_FFMPEG_TESTS'] != '1' ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );
}
