import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository_factory_io.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

void main() {
  test('caption style, color, backdrop and timing render through the export filter', () async {
    try {
      final probe = await Process.run('ffmpeg', ['-version']);
      if (probe.exitCode != 0) markTestSkipped('FFmpeg is unavailable.');
    } on ProcessException {
      markTestSkipped('FFmpeg is unavailable.');
    }
    final renderer = DesktopPreviewRendererRepository(
      logger: AppLogger(appTalker),
    );
    final result = await renderer.buildPreviewVideo(
      BuildPreviewVideoRequest(
        projectId:
            'caption-style-parity-${DateTime.now().microsecondsSinceEpoch}',
        clips: [
          const MediaTrackClipPayload(
            clipId: 'caption-style',
            mediaId: 'caption-style-media',
            title: 'Привет, summer',
            tagline: 'A subtitle line',
            start: Duration.zero,
            end: Duration(seconds: 1),
            sourcePath: 'lib/assets/icon.png',
            imageFit: VideoTemplateImageFit.cover,
            motionOverride: ClipMotionPreset.none,
            caption: 'Привет, summer',
            captionSupportingLine: 'A subtitle line',
            captionSettings: CaptionSettings(
              preset: CaptionStylePreset.bold,
              sizeScale: 1.15,
              textColor: CaptionTextColor.black,
              backdrop: CaptionBackdrop.strongPanel,
              entrance: CaptionEntrance.fade,
              startFraction: 0.25,
              endFraction: 0.75,
            ),
          ),
        ],
        audioSourcePath: null,
        width: 320,
        height: 568,
        frameRate: 10,
      ),
    );
    final outputDirectory = File(result.outputPath).parent;
    addTearDown(() async {
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
    });

    Future<String> frameHash(String time) async {
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

    final before = await frameHash('0.1');
    final during = await frameHash('0.4');
    final after = await frameHash('0.9');
    expect(during, isNot(before));
    expect(during, isNot(after));
  }, skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS));
}
