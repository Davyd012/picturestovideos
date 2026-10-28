import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository_factory_io.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/editor_preview_frame.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/theme/app_theme.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/widgets/mobile_editor_preview_card.dart';

String? _parityTracePath;
const _runFfmpegTests = bool.fromEnvironment('RUN_FFMPEG_TESTS');

void main() {
  testWidgets(
    'desktop editing preview matches decoded export across framing cases',
    (tester) async {
      final outputPrefix =
          '${Directory.systemTemp.path}/picturestovideos-desktop-parity-'
          '${DateTime.now().microsecondsSinceEpoch}';
      _parityTracePath = '$outputPrefix-trace.log';
      _traceParity('test started', reset: true);
      _traceParity('temp created');
      final landscape = _fixturePath('landscape.png');
      final portrait = _fixturePath('portrait.png');
      final square = _fixturePath('square.png');
      final cases = <_ParityCase>[
        _ParityCase(
          name: 'landscape-cover-corner',
          sourcePath: landscape,
          outputWidth: 320,
          outputHeight: 180,
          fit: VideoTemplateImageFit.cover,
          crop: const ImageCropTransform(focalX: 1, focalY: 1, zoom: 1.5),
        ),
        _ParityCase(
          name: 'landscape-cover-fractional',
          sourcePath: landscape,
          outputWidth: 320,
          outputHeight: 180,
          fit: VideoTemplateImageFit.cover,
          crop: const ImageCropTransform(focalX: 0.7, focalY: -0.4, zoom: 1.5),
        ),
        _ParityCase(
          name: 'portrait-contain-landscape-output',
          sourcePath: portrait,
          outputWidth: 320,
          outputHeight: 180,
          fit: VideoTemplateImageFit.contain,
          crop: ImageCropTransform.centered,
        ),
        _ParityCase(
          name: 'square-cover-portrait-output',
          sourcePath: square,
          outputWidth: 180,
          outputHeight: 320,
          fit: VideoTemplateImageFit.cover,
          crop: const ImageCropTransform(focalX: -0.5, focalY: 0.8, zoom: 1.4),
        ),
      ];
      _traceParity('cases ready');
      final renderer = DesktopPreviewRendererRepository(
        logger: AppLogger(appTalker),
      );
      final failures = <String>[];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final parityCase in cases) {
        final request = BuildPreviewVideoRequest(
          projectId: 'desktop-parity-${parityCase.name}',
          clips: [
            MediaTrackClipPayload(
              clipId: 'desktop-parity-clip',
              mediaId: parityCase.name,
              title: 'Generated landmark fixture',
              tagline: '',
              start: Duration.zero,
              end: const Duration(seconds: 2),
              sourcePath: parityCase.sourcePath,
              imageFit: parityCase.fit,
              cropTransform: parityCase.crop,
              motionOverride: ClipMotionPreset.none,
              transitionOverride: ClipTransitionType.cut,
            ),
          ],
          audioSourcePath: null,
          width: parityCase.outputWidth,
          height: parityCase.outputHeight,
          frameRate: 10,
          includeThumbnails: true,
        );
        tester.view.physicalSize = Size(
          parityCase.outputWidth.toDouble(),
          parityCase.outputHeight.toDouble(),
        );
        final evaluated = const CompositionEvaluator().evaluate(
          request.composition,
          Duration.zero,
        );
        final payload = evaluated.layers.single.clip.toPayload();
        final previewFrame = EditorPreviewFrame(
          currentTime: evaluated.time,
          activeIndex: 0,
          progress: evaluated.layers.single.progress,
          clips: [payload],
          activeClip: payload,
          compositionFrame: evaluated,
        );
        final previewKey = GlobalKey();
        _traceParity('before pump ${parityCase.name}');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: RepaintBoundary(
              key: previewKey,
              child: CompositionPreviewCanvas(
                frame: previewFrame,
                template: request.template,
              ),
            ),
          ),
        );
        _traceParity('after pump ${parityCase.name}');
        for (var attempt = 0; attempt < 40; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
          if (tester.widget<RawImage>(find.byType(RawImage)).image != null) {
            break;
          }
        }
        final rawImage = tester.widget<RawImage>(find.byType(RawImage));
        expect(rawImage.image, isNotNull, reason: parityCase.name);
        _traceParity('image ready ${parityCase.name}');
        final boundary =
            previewKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        _traceParity('before capture ${parityCase.name}');
        final image = (await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        ))!;
        _traceParity('after capture ${parityCase.name}');
        late final Uint8List previewBytes;
        late final Uint8List previewPngBytes;
        try {
          previewBytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!.buffer.asUint8List();
          previewPngBytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          ))!.buffer.asUint8List();
        } finally {
          image.dispose();
        }
        await tester.runAsync(
          () =>
              File('$outputPrefix-${parityCase.name}-preview.png')
                  .writeAsBytes(previewPngBytes),
        );

        final rendered = (await tester.runAsync(
          () => renderer.buildPreviewVideo(request),
        ))!;
        _traceParity('renderer done ${parityCase.name}');
        final decodedPath = '$outputPrefix-${parityCase.name}.png';
        try {
          final filterCodec = (await tester.runAsync(
            () => ui.instantiateImageCodec(
              rendered.thumbnails.single.bytes,
              targetWidth: parityCase.outputWidth,
              targetHeight: parityCase.outputHeight,
            ),
          ))!;
          late final _PixelDifference filterDifference;
          final filterArtifactPath =
              '$outputPrefix-${parityCase.name}-filter.png';
          await tester.runAsync(
            () =>
                File(filterArtifactPath)
                    .writeAsBytes(rendered.thumbnails.single.bytes),
          );
          try {
            final filterImage = (await tester.runAsync(
              () => filterCodec.getNextFrame(),
            ))!.image;
            try {
              final filterBytes = (await tester.runAsync(
                () =>
                    filterImage.toByteData(format: ui.ImageByteFormat.rawRgba),
              ))!.buffer.asUint8List();
              filterDifference = _pixelDifference(previewBytes, filterBytes);
            } finally {
              filterImage.dispose();
            }
          } finally {
            filterCodec.dispose();
          }

          final decoder = (await tester.runAsync(
            () => Process.run('ffmpeg', [
              '-v',
              'error',
              '-y',
              '-i',
              rendered.outputPath,
              '-frames:v',
              '1',
              '-update',
              '1',
              decodedPath,
            ]),
          ))!;
          expect(decoder.exitCode, 0, reason: decoder.stderr.toString());
          final decodedFileBytes = (await tester.runAsync(
            () => File(decodedPath).readAsBytes(),
          ))!;
          await tester.runAsync(
            () =>
                File('$outputPrefix-${parityCase.name}-decoded.png')
                    .writeAsBytes(decodedFileBytes),
          );
          final decodedCodec = (await tester.runAsync(
            () => ui.instantiateImageCodec(
              decodedFileBytes,
              targetWidth: parityCase.outputWidth,
              targetHeight: parityCase.outputHeight,
            ),
          ))!;
          late final _PixelDifference encodedDifference;
          try {
            final decodedImage = (await tester.runAsync(
              () => decodedCodec.getNextFrame(),
            ))!.image;
            try {
              final decodedRgba = (await tester.runAsync(
                () =>
                    decodedImage.toByteData(format: ui.ImageByteFormat.rawRgba),
              ))!.buffer.asUint8List();
              encodedDifference = _pixelDifference(previewBytes, decodedRgba);
            } finally {
              decodedImage.dispose();
            }
          } finally {
            decodedCodec.dispose();
          }

          debugPrint(
            'Windows preview/export ${parityCase.name}: '
            'filter=$filterDifference, decoded=$encodedDifference',
          );
          if (filterDifference.mean > 3 || filterDifference.p99 > 16) {
            failures.add(
              '${parityCase.name} filter=$filterDifference exceeds '
              'MAE 3/255 or p99 16/255',
            );
          }
          if (encodedDifference.mean > 3 || encodedDifference.p99 > 16) {
            failures.add(
              '${parityCase.name} decoded=$encodedDifference exceeds '
              'MAE 3/255 or p99 16/255',
            );
          }
        } finally {
          final renderDirectory = Directory(
            File(rendered.outputPath).parent.path,
          );
          if (renderDirectory.existsSync()) {
            renderDirectory.deleteSync(recursive: true);
          }
          final decodedFile = File(decodedPath);
          if (decodedFile.existsSync()) {
            decodedFile.deleteSync();
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    skip:
        (!_runFfmpegTests && Platform.environment['RUN_FFMPEG_TESTS'] != '1') ||
        !Platform.isWindows,
  );
}

String _fixturePath(String name) =>
    File('test/fixtures/generated/$name').absolute.path;

void _traceParity(String message, {bool reset = false}) {
  File(_parityTracePath!).writeAsStringSync(
    '$message\n',
    mode: reset ? FileMode.write : FileMode.append,
    flush: true,
  );
}

class _ParityCase {
  const _ParityCase({
    required this.name,
    required this.sourcePath,
    required this.outputWidth,
    required this.outputHeight,
    required this.fit,
    required this.crop,
  });

  final String name;
  final String sourcePath;
  final int outputWidth;
  final int outputHeight;
  final VideoTemplateImageFit fit;
  final ImageCropTransform crop;
}

_PixelDifference _pixelDifference(List<int> reference, List<int> candidate) {
  expect(candidate.length, reference.length);
  final errors = <int>[];
  for (var index = 0; index < reference.length; index += 4) {
    for (var channel = 0; channel < 3; channel++) {
      errors.add(
        (reference[index + channel] - candidate[index + channel]).abs(),
      );
    }
  }
  errors.sort();
  return _PixelDifference(
    errors.reduce((left, right) => left + right) / errors.length,
    errors[(errors.length * 99 ~/ 100).clamp(0, errors.length - 1)],
  );
}

class _PixelDifference {
  const _PixelDifference(this.mean, this.p99);

  final double mean;
  final int p99;

  @override
  String toString() => 'mean=${mean.toStringAsFixed(2)}/255, p99=$p99/255';
}
