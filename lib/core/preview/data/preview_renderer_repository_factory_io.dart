import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';

PreviewRendererRepository createPreviewRendererRepository(AppLogger logger) {
  if (Platform.isAndroid) {
    return AndroidPreviewRendererRepository(logger: logger);
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return DesktopPreviewRendererRepository(logger: logger);
  }
  return const UnsupportedPreviewRendererRepository();
}

class DesktopPreviewRendererRepository implements PreviewRendererRepository {
  const DesktopPreviewRendererRepository({required this._logger});

  final AppLogger _logger;
  static const _tag = 'DesktopPreviewRendererRepository';

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
  }) async {
    if (!_isDesktopPlatform) {
      throw UnsupportedError('FFmpeg preview is limited to desktop platforms.');
    }

    _logger.info(
      _tag,
      'Starting FFmpeg preview render for ${request.clips.length} clips',
    );
    await _verifyDesktopFfmpeg();

    try {
      onProgress?.call(
        const BuildPreviewVideoProgress(
          completedSteps: 0,
          totalSteps: 1,
          currentStepLabel: 'Rendering video export',
        ),
      );
      final result = await Isolate.run(
        () => _renderPreviewVideoOnWorker(request),
      );
      onProgress?.call(
        const BuildPreviewVideoProgress(
          completedSteps: 0,
          totalSteps: 1,
          currentStepLabel: 'Rendering video export',
          currentStepProgress: 1,
        ),
      );
      _logger.info(
        _tag,
        'FFmpeg preview render finished at ${result.outputPath}',
      );
      return result;
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        error,
        stackTrace,
        message: 'FFmpeg preview rendering failed',
      );
      rethrow;
    }
  }

  bool get _isDesktopPlatform =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

class AndroidPreviewRendererRepository implements PreviewRendererRepository {
  const AndroidPreviewRendererRepository({required AppLogger logger})
    : this._(logger);

  const AndroidPreviewRendererRepository._(this._logger);

  final AppLogger _logger;
  static const _tag = 'AndroidPreviewRendererRepository';

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
  }) async {
    _logger.info(
      _tag,
      'Starting Android FFmpeg render for ${request.clips.length} clips',
    );

    try {
      final tempRoot = await getTemporaryDirectory();
      final result = await _renderPreviewVideo(
        request,
        tempRoot: tempRoot,
        segmentVideoArgs: const ['-c:v', 'mpeg4', '-q:v', '4'],
        runFfmpeg: _runAndroidFfmpeg,
        onProgress: onProgress,
      );
      _logger.info(
        _tag,
        'Android FFmpeg render finished at ${result.outputPath}',
      );
      return result;
    } catch (error, stackTrace) {
      _logger.error(
        _tag,
        error,
        stackTrace,
        message: 'Android FFmpeg rendering failed',
      );
      rethrow;
    }
  }
}

class UnsupportedPreviewRendererRepository
    implements PreviewRendererRepository {
  const UnsupportedPreviewRendererRepository();

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
  }) {
    throw UnsupportedError(
      'Preview rendering is only available on Android and desktop platforms.',
    );
  }
}

Future<void> _verifyDesktopFfmpeg() async {
  final ffmpegResult = await Process.run('ffmpeg', const [
    '-version',
  ], runInShell: false);
  if (ffmpegResult.exitCode != 0) {
    throw ProcessException(
      'ffmpeg',
      const ['-version'],
      'FFmpeg was not found on PATH.',
      ffmpegResult.exitCode,
    );
  }
}

Future<BuildPreviewVideoResult> _renderPreviewVideoOnWorker(
  BuildPreviewVideoRequest request,
) async {
  return _renderPreviewVideo(
    request,
    tempRoot: Directory.systemTemp,
    segmentVideoArgs: const ['-c:v', 'libx264'],
    runFfmpeg: _runDesktopFfmpeg,
  );
}

Future<BuildPreviewVideoResult> _renderPreviewVideo(
  BuildPreviewVideoRequest request, {
  required Directory tempRoot,
  required List<String> segmentVideoArgs,
  required _RunFfmpeg runFfmpeg,
  BuildPreviewVideoProgressCallback? onProgress,
}) async {
  final signature = _buildSignature(request);
  final tempDir = await tempRoot.createTemp('picturestovideos-preview-');
  final cacheDir = Directory('${tempRoot.path}/picturestovideos-preview-cache');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  final segmentPaths = <String>[];
  final thumbnails = <PreviewImageFrame>[];
  final totalSteps = request.clips.length * 2 + 1;
  var completedSteps = 0;

  void emitProgress(String label, {double stepProgress = 0}) {
    onProgress?.call(
      BuildPreviewVideoProgress(
        completedSteps: completedSteps,
        totalSteps: totalSteps,
        currentStepLabel: label,
        currentStepProgress: stepProgress,
      ),
    );
  }

  Future<void> runStep(
    String label,
    List<String> args, {
    Duration? expectedDuration,
  }) async {
    emitProgress(label);
    await runFfmpeg(
      args,
      expectedDuration: expectedDuration,
      onProgress: (progress) => emitProgress(label, stepProgress: progress),
    );
    emitProgress(label, stepProgress: 1);
    completedSteps++;
  }

  void completeCachedStep(String label) {
    emitProgress(label, stepProgress: 1);
    completedSteps++;
  }

  for (var index = 0; index < request.clips.length; index++) {
    final clip = request.clips[index];
    final sourceFile = File(clip.sourcePath);
    if (!sourceFile.existsSync()) {
      throw FileSystemException(
        'Image file is missing for preview rendering.',
        clip.sourcePath,
      );
    }
    final sourceStat = sourceFile.statSync();
    final durationSeconds = _durationSeconds(clip);
    final filter = _buildVisualFilter(
      clip: clip,
      template: request.template,
      width: request.width,
      height: request.height,
    );
    final cacheKey = _previewClipCacheKey(
      clip: clip,
      sourceStat: sourceStat,
      width: request.width,
      height: request.height,
      frameRate: request.frameRate,
      template: request.template,
      segmentVideoArgs: segmentVideoArgs,
    );
    final thumbnailPath = '${cacheDir.path}/$cacheKey.png';
    final segmentPath = '${cacheDir.path}/$cacheKey.mp4';

    if (!File(thumbnailPath).existsSync()) {
      final renderPath = '${tempDir.path}/thumbnail_$index.png';
      await runStep('Rendering thumbnail ${index + 1}', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        clip.sourcePath,
        '-vf',
        filter,
        '-frames:v',
        '1',
        renderPath,
      ]);
      await File(renderPath).copy(thumbnailPath);
    } else {
      completeCachedStep('Using cached thumbnail ${index + 1}');
    }

    if (!File(segmentPath).existsSync()) {
      final renderPath = '${tempDir.path}/segment_$index.mp4';
      await runStep(
        'Rendering clip ${index + 1} of ${request.clips.length}',
        [
          '-hide_banner',
          '-loglevel',
          'error',
          '-y',
          '-loop',
          '1',
          '-i',
          clip.sourcePath,
          '-vf',
          filter,
          '-t',
          '$durationSeconds',
          '-r',
          '${request.frameRate}',
          '-pix_fmt',
          'yuv420p',
          ...segmentVideoArgs,
          renderPath,
        ],
        expectedDuration: clip.end - clip.start,
      );
      await File(renderPath).copy(segmentPath);
    } else {
      completeCachedStep('Using cached clip ${index + 1}');
    }

    thumbnails.add(
      PreviewImageFrame(
        clipId: clip.mediaId,
        bytes: await File(thumbnailPath).readAsBytes(),
      ),
    );
    segmentPaths.add(segmentPath);
  }

  final concatFile = File('${tempDir.path}/concat.txt');
  await concatFile.writeAsString(
    segmentPaths.map((path) => "file '$path'").join('\n'),
  );
  final outputPath = '${tempDir.path}/${request.outputFileName}';
  final audioSourcePath = request.audioSourcePath;
  final hasAudioSource =
      audioSourcePath != null &&
      audioSourcePath.isNotEmpty &&
      File(audioSourcePath).existsSync();
  final totalDurationSeconds = request.clips.last.end.inMilliseconds / 1000;

  if (hasAudioSource) {
    await runStep('Combining video and audio', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      concatFile.path,
      '-i',
      audioSourcePath,
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-t',
      '$totalDurationSeconds',
      '-shortest',
      outputPath,
    ], expectedDuration: request.clips.last.end);
  } else {
    await runStep('Combining video segments', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      concatFile.path,
      '-c',
      'copy',
      outputPath,
    ], expectedDuration: request.clips.last.end);
  }

  return BuildPreviewVideoResult(
    outputPath: outputPath,
    signature: signature,
    totalDuration: request.clips.last.end,
    thumbnails: List.unmodifiable(thumbnails),
  );
}

typedef _RunFfmpeg =
    Future<void> Function(
      List<String> args, {
      Duration? expectedDuration,
      void Function(double progress)? onProgress,
    });

Future<void> _runDesktopFfmpeg(
  List<String> args, {
  Duration? expectedDuration,
  void Function(double progress)? onProgress,
}) async {
  final result = await Process.run('ffmpeg', args, runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'ffmpeg',
      args,
      result.stderr.toString(),
      result.exitCode,
    );
  }
}

Future<void> _runAndroidFfmpeg(
  List<String> args, {
  Duration? expectedDuration,
  void Function(double progress)? onProgress,
}) async {
  await FFmpegKitExtended.initialize();
  final session = FFmpegKit.createSessionFromArguments(args);
  session.setExpectedTranscodingDuration(expectedDuration);
  session.setStatisticsCallback((statistics) {
    final progress =
        statistics.transcodingProgress ??
        session.calculateTranscodingProgress(statistics.time);
    if (progress != null) {
      onProgress?.call(progress);
    }
  });
  await session.executeAsync();
  final returnCode = session.getReturnCode();
  if (ReturnCode.isSuccess(returnCode)) {
    return;
  }

  final output = session.getOutput();
  final stackTrace = session.getFailStackTrace();
  throw ProcessException(
    'ffmpeg-kit',
    args,
    [output, stackTrace].whereType<String>().join('\n'),
    returnCode,
  );
}

String _buildVisualFilter({
  required MediaTrackClipPayload clip,
  required VideoTemplate template,
  required int width,
  required int height,
}) {
  final title = _escapeDrawText(clip.title);
  final subtitle = _escapeDrawText(clip.tagline);
  final filters = <String>[
    _imageFilter(template: template, width: width, height: height),
    ..._frameFilters(template: template, width: width, height: height),
    ..._overlayFilters(template: template, width: width, height: height),
    ..._textFilters(
      template: template,
      title: title,
      subtitle: subtitle,
      width: width,
      height: height,
    ),
  ];

  return filters.join(',');
}

String _imageFilter({
  required VideoTemplate template,
  required int width,
  required int height,
}) {
  if (template.imageFit == VideoTemplateImageFit.cover) {
    return [
      'scale=w=$width:h=$height:force_original_aspect_ratio=increase',
      'crop=$width:$height',
    ].join(',');
  }

  final backgroundColor =
      template.frameStyle == VideoTemplateFrameStyle.polaroid
      ? '0xF4EFE7'
      : 'black';

  return [
    'scale=w=$width:h=$height:force_original_aspect_ratio=decrease',
    'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:$backgroundColor',
  ].join(',');
}

List<String> _frameFilters({
  required VideoTemplate template,
  required int width,
  required int height,
}) {
  return switch (template.frameStyle) {
    VideoTemplateFrameStyle.polaroid => [
      'drawbox=x=${width ~/ 12}:y=${height ~/ 8}:w=${width - (width ~/ 6)}:h=${height - (height ~/ 4)}:color=white@0.96:t=20',
      'drawbox=x=${width ~/ 12}:y=${height ~/ 8}:w=${width - (width ~/ 6)}:h=${height - (height ~/ 4)}:color=black@0.18:t=2',
    ],
    VideoTemplateFrameStyle.cleanBorder => [
      'drawbox=x=${width ~/ 20}:y=${height ~/ 24}:w=${width - (width ~/ 10)}:h=${height - (height ~/ 12)}:color=white@0.20:t=3',
    ],
    VideoTemplateFrameStyle.none => const [],
  };
}

List<String> _overlayFilters({
  required VideoTemplate template,
  required int width,
  required int height,
}) {
  return switch (template.overlayStyle) {
    VideoTemplateOverlayStyle.bottomScrim => [
      'drawbox=x=0:y=${height * 2 ~/ 3}:w=$width:h=${height ~/ 3}:color=black@0.38:t=fill',
    ],
    VideoTemplateOverlayStyle.cinematicScrim => [
      'drawbox=x=0:y=0:w=$width:h=$height:color=black@0.18:t=fill',
      'drawbox=x=0:y=${height * 3 ~/ 5}:w=$width:h=${height * 2 ~/ 5}:color=black@0.48:t=fill',
    ],
    VideoTemplateOverlayStyle.textPanel => [
      'drawbox=x=${width ~/ 14}:y=${height * 2 ~/ 3}:w=${width - (width ~/ 7)}:h=${height ~/ 5}:color=black@0.52:t=fill',
      'drawbox=x=${width ~/ 14}:y=${height * 2 ~/ 3}:w=${width - (width ~/ 7)}:h=${height ~/ 5}:color=white@0.18:t=2',
    ],
    VideoTemplateOverlayStyle.none => const [],
  };
}

List<String> _textFilters({
  required VideoTemplate template,
  required String title,
  required String subtitle,
  required int width,
  required int height,
}) {
  final titleSize = _titleFontSize(template, height);
  final subtitleSize = _subtitleFontSize(template, height);
  final titlePosition = _titlePosition(template, width, height);
  final subtitlePosition = _subtitlePosition(template, width, height);
  final textColor = template.frameStyle == VideoTemplateFrameStyle.polaroid
      ? 'black'
      : 'white';
  final filters = <String>[
    "drawtext=text='$title':x=${titlePosition.x}:y=${titlePosition.y}:fontsize=$titleSize:fontcolor=$textColor",
  ];

  if (subtitle.isNotEmpty) {
    filters.add(
      "drawtext=text='$subtitle':x=${subtitlePosition.x}:y=${subtitlePosition.y}:fontsize=$subtitleSize:fontcolor=$textColor",
    );
  }

  return filters;
}

_TextPosition _titlePosition(VideoTemplate template, int width, int height) {
  return switch (template.textPlacement) {
    VideoTemplateTextPlacement.center => const _TextPosition(
      x: '(w-text_w)/2',
      y: '(h-text_h)/2',
    ),
    VideoTemplateTextPlacement.lowerThird => _TextPosition(
      x: '${width ~/ 12}',
      y: '${height * 2 ~/ 3}',
    ),
    VideoTemplateTextPlacement.belowImage => _TextPosition(
      x: '(w-text_w)/2',
      y: '${height * 5 ~/ 6}',
    ),
    VideoTemplateTextPlacement.insideTextBox => _TextPosition(
      x: '${width ~/ 10}',
      y: '${height * 2 ~/ 3 + height ~/ 20}',
    ),
    VideoTemplateTextPlacement.bottomCenter => _TextPosition(
      x: '(w-text_w)/2',
      y: '${height - (height ~/ 5)}',
    ),
  };
}

_TextPosition _subtitlePosition(VideoTemplate template, int width, int height) {
  return switch (template.textPlacement) {
    VideoTemplateTextPlacement.center => _TextPosition(
      x: '(w-text_w)/2',
      y: '${height ~/ 2 + height ~/ 16}',
    ),
    VideoTemplateTextPlacement.lowerThird => _TextPosition(
      x: '${width ~/ 12}',
      y: '${height * 2 ~/ 3 + height ~/ 14}',
    ),
    VideoTemplateTextPlacement.belowImage => _TextPosition(
      x: '(w-text_w)/2',
      y: '${height * 5 ~/ 6 + height ~/ 24}',
    ),
    VideoTemplateTextPlacement.insideTextBox => _TextPosition(
      x: '${width ~/ 10}',
      y: '${height * 2 ~/ 3 + height ~/ 9}',
    ),
    VideoTemplateTextPlacement.bottomCenter => _TextPosition(
      x: '(w-text_w)/2',
      y: '${height - (height ~/ 8)}',
    ),
  };
}

int _titleFontSize(VideoTemplate template, int height) {
  final base = height ~/ 20;
  return switch (template.textPlacement) {
    VideoTemplateTextPlacement.center => base + 18,
    VideoTemplateTextPlacement.lowerThird => base + 10,
    VideoTemplateTextPlacement.insideTextBox => base,
    _ => base + 4,
  };
}

int _subtitleFontSize(VideoTemplate template, int height) {
  final base = height ~/ 34;
  return template.textPlacement == VideoTemplateTextPlacement.center
      ? base + 8
      : base;
}

class _TextPosition {
  const _TextPosition({required this.x, required this.y});

  final String x;
  final String y;
}

String _escapeDrawText(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll(':', r'\:')
      .replaceAll("'", r"\'")
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');
}

double _durationSeconds(MediaTrackClipPayload clip) {
  final duration = clip.end - clip.start;
  final safeDuration = duration > Duration.zero
      ? duration
      : const Duration(milliseconds: 500);
  return safeDuration.inMilliseconds / 1000;
}

String _buildSignature(BuildPreviewVideoRequest request) {
  return [
    request.projectId,
    _templateSignature(request.template),
    request.audioSourcePath ?? 'no-audio',
    '${request.width}x${request.height}',
    '${request.frameRate}',
    for (final clip in request.clips)
      '${clip.mediaId}:${clip.start.inMilliseconds}:${clip.end.inMilliseconds}:${clip.title}:${clip.tagline}:${clip.sourcePath}',
  ].join('|');
}

String _previewClipCacheKey({
  required MediaTrackClipPayload clip,
  required FileStat sourceStat,
  required int width,
  required int height,
  required int frameRate,
  required VideoTemplate template,
  required List<String> segmentVideoArgs,
}) {
  return _stableHexKey([
    clip.mediaId,
    clip.title,
    clip.tagline,
    clip.sourcePath,
    clip.start.inMilliseconds,
    clip.end.inMilliseconds,
    sourceStat.size,
    sourceStat.modified.millisecondsSinceEpoch,
    _templateSignature(template),
    width,
    height,
    frameRate,
    segmentVideoArgs.join(' '),
  ]);
}

String _templateSignature(VideoTemplate template) {
  return template
      .toJson()
      .entries
      .map((entry) {
        return '${entry.key}:${entry.value}';
      })
      .join(';');
}

String _stableHexKey(List<Object?> parts) {
  var hash = 0xcbf29ce484222325;
  for (final codeUnit in parts.join('|').codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
