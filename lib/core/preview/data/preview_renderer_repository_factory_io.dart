import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
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
    BuildPreviewVideoRequest request,
  ) async {
    if (!_isDesktopPlatform) {
      throw UnsupportedError('FFmpeg preview is limited to desktop platforms.');
    }

    _logger.info(
      _tag,
      'Starting FFmpeg preview render for ${request.clips.length} clips',
    );
    await _verifyDesktopFfmpeg();

    try {
      final result = await Isolate.run(
        () => _renderPreviewVideoOnWorker(request),
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
    BuildPreviewVideoRequest request,
  ) async {
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
    BuildPreviewVideoRequest request,
  ) {
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
  required Future<void> Function(List<String> args) runFfmpeg,
}) async {
  final signature = _buildSignature(request);
  final tempDir = await tempRoot.createTemp('picturestovideos-preview-');
  final cacheDir = Directory('${tempRoot.path}/picturestovideos-preview-cache');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  final segmentPaths = <String>[];
  final thumbnails = <PreviewImageFrame>[];

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
      width: request.width,
      height: request.height,
    );
    final cacheKey = _previewClipCacheKey(
      clip: clip,
      sourceStat: sourceStat,
      width: request.width,
      height: request.height,
      frameRate: request.frameRate,
      segmentVideoArgs: segmentVideoArgs,
    );
    final thumbnailPath = '${cacheDir.path}/$cacheKey.png';
    final segmentPath = '${cacheDir.path}/$cacheKey.mp4';

    if (!File(thumbnailPath).existsSync()) {
      final renderPath = '${tempDir.path}/thumbnail_$index.png';
      await runFfmpeg([
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
    }

    if (!File(segmentPath).existsSync()) {
      final renderPath = '${tempDir.path}/segment_$index.mp4';
      await runFfmpeg([
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
      ]);
      await File(renderPath).copy(segmentPath);
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
    await runFfmpeg([
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
    ]);
  } else {
    await runFfmpeg([
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
    ]);
  }

  return BuildPreviewVideoResult(
    outputPath: outputPath,
    signature: signature,
    totalDuration: request.clips.last.end,
    thumbnails: List.unmodifiable(thumbnails),
  );
}

Future<void> _runDesktopFfmpeg(List<String> args) async {
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

Future<void> _runAndroidFfmpeg(List<String> args) async {
  await FFmpegKitExtended.initialize();
  final session = FFmpegKit.createSessionFromArguments(args);
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
  required int width,
  required int height,
}) {
  final title = _escapeDrawText(clip.title);
  final subtitle = _escapeDrawText(
    clip.tagline.isEmpty ? 'IMAGE CLIP' : clip.tagline.toUpperCase(),
  );
  final label = _escapeDrawText('BEAT-SYNCED IMAGE');
  final panelY = height - 212;
  final subtitleY = height - 126;
  final labelY = height - 190;

  return [
    'scale=w=$width:h=$height:force_original_aspect_ratio=decrease',
    'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:black',
    'drawbox=x=48:y=${height - 244}:w=${width - 96}:h=196:color=black@0.30:t=fill',
    'drawbox=x=48:y=${height - 244}:w=${width - 96}:h=196:color=white@0.12:t=2',
    "drawtext=text='$label':x=72:y=$labelY:fontsize=26:fontcolor=white",
    "drawtext=text='$title':x=72:y=$panelY:fontsize=52:fontcolor=white",
    "drawtext=text='$subtitle':x=72:y=$subtitleY:fontsize=28:fontcolor=white",
  ].join(',');
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
    width,
    height,
    frameRate,
    segmentVideoArgs.join(' '),
  ]);
}

String _stableHexKey(List<Object?> parts) {
  var hash = 0xcbf29ce484222325;
  for (final codeUnit in parts.join('|').codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
