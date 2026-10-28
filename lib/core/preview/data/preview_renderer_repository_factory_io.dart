import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/core/preview/data/preview_renderer_repository.dart';
import 'package:picturestovideos/core/preview/data/render_segment_cache.dart';
import 'package:picturestovideos/core/preview/data/render_temp_directory_manager.dart';
import 'package:picturestovideos/core/preview/data/source_content_fingerprint.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository_factory_io.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_request.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/composition/domain/composition_evaluator.dart';
import 'package:picturestovideos/core/composition/domain/frame_time_quantizer.dart';
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
  const DesktopPreviewRendererRepository({
    required this._logger,
    RenderCapabilityRepository? capabilityRepository,
  }) : _capabilityRepository =
           capabilityRepository ?? const IoRenderCapabilityRepository();

  final AppLogger _logger;
  final RenderCapabilityRepository _capabilityRepository;
  static const _tag = 'DesktopPreviewRendererRepository';

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) async {
    if (!_isDesktopPlatform) {
      throw const RenderCapabilityException(
        RenderCapabilityIssue.unsupportedPlatform,
      );
    }

    _logger.info(
      _tag,
      'Starting FFmpeg preview render for ${request.clips.length} clips',
    );
    cancellation?.throwIfCancelled();
    final capabilities = await _capabilityRepository.probe();
    capabilities.requireFor(request.composition);
    cancellation?.throwIfCancelled();

    try {
      final result = await _renderPreviewVideo(
        request,
        tempRoot: Directory.systemTemp,
        segmentVideoArgs: const ['-c:v', 'libx264', '-preset', 'veryfast'],
        runFfmpeg: _runDesktopFfmpeg,
        fontPath: capabilities.fontPath,
        fontSignature: capabilities.fontSignature,
        rendererVersion: capabilities.version,
        onProgress: onProgress,
        cancellation: cancellation,
      );
      _logger.info(
        _tag,
        'FFmpeg preview render finished at ${result.outputPath}',
      );
      return result;
    } on RenderCancelled {
      _logger.info(_tag, 'FFmpeg preview render cancelled');
      rethrow;
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
  const AndroidPreviewRendererRepository({
    required this._logger,
    RenderCapabilityRepository? capabilityRepository,
  }) : _capabilityRepository =
           capabilityRepository ?? const IoRenderCapabilityRepository();

  final AppLogger _logger;
  final RenderCapabilityRepository _capabilityRepository;
  static const _tag = 'AndroidPreviewRendererRepository';

  @override
  Future<BuildPreviewVideoResult> buildPreviewVideo(
    BuildPreviewVideoRequest request, {
    BuildPreviewVideoProgressCallback? onProgress,
    RenderCancellation? cancellation,
  }) async {
    _logger.info(
      _tag,
      'Starting Android FFmpeg render for ${request.clips.length} clips',
    );

    try {
      final capabilities = await _capabilityRepository.probe();
      capabilities.requireFor(request.composition);
      final tempRoot = await getTemporaryDirectory();
      final result = await _renderPreviewVideo(
        request,
        tempRoot: tempRoot,
        segmentVideoArgs: const ['-c:v', 'mpeg4', '-q:v', '4'],
        runFfmpeg: _runAndroidFfmpeg,
        fontPath: capabilities.fontPath,
        fontSignature: capabilities.fontSignature,
        rendererVersion: capabilities.version,
        onProgress: onProgress,
        cancellation: cancellation,
      );
      _logger.info(
        _tag,
        'Android FFmpeg render finished at ${result.outputPath}',
      );
      return result;
    } on RenderCancelled {
      _logger.info(_tag, 'Android FFmpeg render cancelled');
      rethrow;
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
    RenderCancellation? cancellation,
  }) {
    throw const RenderCapabilityException(
      RenderCapabilityIssue.unsupportedPlatform,
    );
  }
}

Future<BuildPreviewVideoResult> _renderPreviewVideo(
  BuildPreviewVideoRequest request, {
  required Directory tempRoot,
  required List<String> segmentVideoArgs,
  required _RunFfmpeg runFfmpeg,
  required String? fontPath,
  required String? fontSignature,
  required String? rendererVersion,
  BuildPreviewVideoProgressCallback? onProgress,
  RenderCancellation? cancellation,
}) async {
  cancellation?.throwIfCancelled();
  final composition = request.composition;
  const evaluator = CompositionEvaluator();
  final validationFailures = composition.validate();
  if (validationFailures.isNotEmpty) {
    throw CompositionValidationException(validationFailures);
  }
  final clips = request.resolvedClips;
  final sourceFingerprints = <String, String>{};
  for (final clip in clips) {
    cancellation?.throwIfCancelled();
    if (sourceFingerprints.containsKey(clip.sourcePath)) continue;
    final sourceFile = File(clip.sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Image file is missing for preview rendering.',
        clip.sourcePath,
      );
    }
    sourceFingerprints[clip.sourcePath] = await sourceContentFingerprint(
      sourceFile,
      onChunk: cancellation?.throwIfCancelled,
    );
    cancellation?.throwIfCancelled();
  }
  final audioSourcePath = request.audioSourcePath;
  if (audioSourcePath != null && audioSourcePath.isNotEmpty) {
    cancellation?.throwIfCancelled();
    final audioFile = File(audioSourcePath);
    if (!await audioFile.exists()) {
      throw FileSystemException(
        'Audio file is missing for preview rendering.',
        audioSourcePath,
      );
    }
    sourceFingerprints[audioSourcePath] ??= await sourceContentFingerprint(
      audioFile,
      onChunk: cancellation?.throwIfCancelled,
    );
    cancellation?.throwIfCancelled();
  }
  final signature = _buildSignature(
    request,
    segmentVideoArgs,
    rendererVersion,
    fontSignature,
    sourceFingerprints,
  );
  final tempDirectoryLease = await RenderTempDirectoryManager(tempRoot)
      .create();
  final tempDir = tempDirectoryLease.directory;
  final cacheDir = Directory('${tempRoot.path}/picturestovideos-preview-cache');
  final segmentPaths = <String>[];
  final thumbnails = <PreviewImageFrame>[];
  final cache = RenderSegmentCache(cacheDir);
  final pinnedPaths = <String>[];
  String? completedOutput;
  final totalSteps =
      clips.length + (request.includeThumbnails ? clips.length : 0) + 1;
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
    cancellation?.throwIfCancelled();
    await runFfmpeg(
      args,
      expectedDuration: expectedDuration,
      onProgress: (progress) => emitProgress(label, stepProgress: progress),
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    emitProgress(label, stepProgress: 1);
    completedSteps++;
  }

  void completeCachedStep(String label) {
    emitProgress(label, stepProgress: 1);
    completedSteps++;
  }

  try {
    await cacheDir.create(recursive: true);
    await cache.prune();
    for (var index = 0; index < clips.length; index++) {
      cancellation?.throwIfCancelled();
      final clip = clips[index];
      final sourceFile = File(clip.sourcePath);
      if (!sourceFile.existsSync()) {
        throw FileSystemException(
          'Image file is missing for preview rendering.',
          clip.sourcePath,
        );
      }
      final sourceStat = sourceFile.statSync();
      final durationSeconds = _durationSeconds(clip);
      final captionLayout = evaluator.captionLayoutFor(
        composition.clips[index],
        composition,
      );
      String? titlePath;
      String? subtitlePath;
      if (clip.caption.isNotEmpty) {
        final file = File('${tempDir.path}/caption_${index}_title.txt');
        await file.writeAsString(captionLayout.titleText);
        titlePath = file.path;
      }
      if (clip.captionSupportingLine.isNotEmpty) {
        final file = File('${tempDir.path}/caption_${index}_support.txt');
        await file.writeAsString(captionLayout.supportText);
        subtitlePath = file.path;
      }
      final filter = _buildVisualFilter(
        clip: clip,
        template: request.template,
        width: request.width,
        height: request.height,
        frameRate: request.frameRate,
        titlePath: titlePath,
        subtitlePath: subtitlePath,
        captionLayout: captionLayout,
        fontPath: fontPath,
      );
      final cacheKey = _previewClipCacheKey(
        clip: clip,
        sourceStat: sourceStat,
        sourceFingerprint: sourceFingerprints[clip.sourcePath]!,
        width: request.width,
        height: request.height,
        frameRate: request.frameRate,
        template: request.template,
        segmentVideoArgs: segmentVideoArgs,
        fontPath: fontPath,
        fontSignature: fontSignature,
        rendererVersion: rendererVersion,
      );
      final thumbnailPath = '${cacheDir.path}/$cacheKey.png';
      final segmentPath = '${cacheDir.path}/$cacheKey.mp4';
      final thumbnailFile = File(thumbnailPath);
      final segmentFile = File(segmentPath);
      cache.pin(segmentPath);
      pinnedPaths.add(segmentPath);
      if (request.includeThumbnails) {
        cache.pin(thumbnailPath);
        pinnedPaths.add(thumbnailPath);
      }

      await cache.withArtifactLock(
        segmentFile,
        cancellation: cancellation,
        action: () async {
          if (!await cache.isValid(
            segmentFile,
            onChunk: cancellation?.throwIfCancelled,
          )) {
            await cache.remove(segmentFile);
            final renderPath = '${tempDir.path}/segment_$index.mp4';
            await runStep('Rendering clip ${index + 1} of ${clips.length}', [
              '-hide_banner',
              '-loglevel',
              'error',
              '-y',
              '-loop',
              '1',
              '-framerate',
              '${request.frameRate}',
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
            ], expectedDuration: clip.end - clip.start);
            cancellation?.throwIfCancelled();
            await cache.publish(File(renderPath), segmentFile);
          } else {
            await cache.touch(segmentFile);
            completeCachedStep('Using cached clip ${index + 1}');
          }
        },
      );

      if (request.includeThumbnails) {
        await cache.withArtifactLock(
          thumbnailFile,
          cancellation: cancellation,
          action: () async {
            if (!await cache.isValid(
              thumbnailFile,
              onChunk: cancellation?.throwIfCancelled,
            )) {
              await cache.remove(thumbnailFile);
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
              cancellation?.throwIfCancelled();
              await cache.publish(File(renderPath), thumbnailFile);
            } else {
              await cache.touch(thumbnailFile);
              completeCachedStep('Using cached thumbnail ${index + 1}');
            }
          },
        );

        thumbnails.add(
          PreviewImageFrame(
            clipId: clip.clipId,
            bytes: await thumbnailFile.readAsBytes(),
          ),
        );
      }
      segmentPaths.add(segmentPath);
    }

    final outputPath = '${tempDir.path}/${request.outputFileName}';
    final audioSourcePath = request.audioSourcePath;
    final hasAudioSource =
        audioSourcePath != null &&
        audioSourcePath.isNotEmpty &&
        File(audioSourcePath).existsSync();
    if (audioSourcePath != null &&
        audioSourcePath.isNotEmpty &&
        !hasAudioSource) {
      throw FileSystemException(
        'Audio file is missing for preview rendering.',
        audioSourcePath,
      );
    }
    final transitions = evaluator.transitionsFor(composition);
    await runStep(
      'Combining video and audio',
      _transitionArguments(
        request: request,
        segmentPaths: segmentPaths,
        transitions: transitions,
        videoArgs: segmentVideoArgs,
        outputPath: outputPath,
        audioSourcePath: hasAudioSource ? audioSourcePath : null,
      ),
      expectedDuration: request.clips.last.end,
    );

    cancellation?.throwIfCancelled();
    for (final entry in sourceFingerprints.entries) {
      cancellation?.throwIfCancelled();
      final current = await sourceContentFingerprint(
        File(entry.key),
        onChunk: cancellation?.throwIfCancelled,
      );
      if (current != entry.value) {
        throw FileSystemException(
          'Image file changed while preview rendering was in progress.',
          entry.key,
        );
      }
    }
    cancellation?.throwIfCancelled();
    completedOutput = outputPath;
    await tempDirectoryLease.markCompleted();
    return BuildPreviewVideoResult(
      outputPath: outputPath,
      signature: signature,
      totalDuration: clips.last.end,
      thumbnails: List.unmodifiable(thumbnails),
    );
  } finally {
    tempDirectoryLease.dispose();
    for (final path in pinnedPaths) {
      cache.unpin(path);
    }
    try {
      await cache.prune();
    } on FileSystemException {
      /* Retry on the next render. */
    }
    if (await tempDir.exists()) {
      await for (final entry in tempDir.list(followLinks: false)) {
        final isOutput =
            completedOutput != null &&
            entry.absolute.uri.normalizePath() ==
                File(completedOutput).absolute.uri.normalizePath();
        if (entry is File &&
            (!isOutput || (cancellation?.isCancelled ?? false))) {
          try {
            await entry.delete();
          } on FileSystemException {
            /* Temporary cleanup can be retried by the OS. */
          }
        }
      }
      if (completedOutput == null || (cancellation?.isCancelled ?? false)) {
        try {
          await tempDir.delete();
        } on FileSystemException {
          /* Temporary cleanup can be retried by the OS. */
        }
      }
    }
  }
}

List<String> _transitionArguments({
  required BuildPreviewVideoRequest request,
  required List<String> segmentPaths,
  required List<ClipTransition> transitions,
  required List<String> videoArgs,
  required String outputPath,
  required String? audioSourcePath,
}) {
  String seconds(Duration duration) =>
      (duration.inMicroseconds / Duration.microsecondsPerSecond)
          .toStringAsFixed(6);
  final clips = request.resolvedClips;
  final filters = <String>[];
  for (var i = 0; i < clips.length; i++) {
    final before = i == 0
        ? clips.first.start
        : transitions[i - 1].duration ~/ 2;
    final after = i == transitions.length
        ? Duration.zero
        : transitions[i].duration - transitions[i].duration ~/ 2;
    final span = i + 1 < clips.length
        ? clips[i + 1].start - clips[i].start
        : clips[i].end - clips[i].start;
    final sourceSpan = clips[i].end - clips[i].start;
    final trim = span < sourceSpan ? span : sourceSpan;
    final gap = span > sourceSpan ? span - sourceSpan : Duration.zero;
    filters.add(
      '[$i:v]trim=duration=${seconds(trim)},setpts=PTS-STARTPTS,fps=${request.frameRate},tpad=start_mode=clone:start_duration=${seconds(before)}:stop_mode=clone:stop_duration=${seconds(after + gap)},settb=AVTB[clip$i]',
    );
  }
  var previous = 'clip0';
  for (var i = 0; i < transitions.length; i++) {
    final transition = transitions[i];
    final next = 'clip${i + 1}';
    final output = 'joined$i';
    if (transition.duration <= Duration.zero) {
      filters.add('[$previous][$next]concat=n=2:v=1:a=0[$output]');
    } else {
      final effect = transition.type == ClipTransitionType.slide
          ? 'slideleft'
          : 'fade';
      filters.add(
        '[$previous][$next]xfade=transition=$effect:duration=${seconds(transition.duration)}:offset=${seconds(transition.start)}[$output]',
      );
    }
    previous = output;
  }
  return [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    for (final path in segmentPaths) ...['-i', path],
    if (audioSourcePath != null) ...['-i', audioSourcePath],
    '-filter_complex_threads',
    '1',
    '-filter_complex',
    filters.join(';'),
    '-map',
    '[$previous]',
    if (audioSourcePath != null) ...[
      '-map',
      '${segmentPaths.length}:a:0',
      '-af',
      _audioFilter(request),
      '-c:a',
      'aac',
    ],
    ...videoArgs,
    '-pix_fmt',
    'yuv420p',
    '-r',
    '${request.frameRate}',
    '-t',
    seconds(clips.last.end),
    outputPath,
  ];
}

String _audioFilter(BuildPreviewVideoRequest request) {
  String seconds(Duration value) =>
      (value.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(
        6,
      );
  final mix = request.audioMix;
  final length = mix.effectiveDuration(
    sourceDuration: request.audioSourceDuration,
    videoDuration: request.clips.last.end,
  );
  if (length <= Duration.zero) {
    throw const FormatException('The selected music range is empty.');
  }
  final fadeLimit = length ~/ 2;
  final fadeIn = mix.fadeIn < fadeLimit ? mix.fadeIn : fadeLimit;
  final fadeOut = mix.fadeOut < fadeLimit ? mix.fadeOut : fadeLimit;
  return [
    'atrim=start=${seconds(mix.start)}:duration=${seconds(length)}',
    'asetpts=PTS-STARTPTS',
    if (fadeIn > Duration.zero) 'afade=t=in:st=0:d=${seconds(fadeIn)}',
    if (fadeOut > Duration.zero)
      'afade=t=out:st=${seconds(length - fadeOut)}:d=${seconds(fadeOut)}',
    'apad',
  ].join(',');
}

typedef _RunFfmpeg = Future<void> Function(
  List<String> args, {
  Duration? expectedDuration,
  void Function(double progress)? onProgress,
  RenderCancellation? cancellation,
});

Future<void> _runDesktopFfmpeg(
  List<String> args, {
  Duration? expectedDuration,
  void Function(double progress)? onProgress,
  RenderCancellation? cancellation,
}) async {
  cancellation?.throwIfCancelled();
  final process = await Process.start('ffmpeg', [
    '-progress',
    'pipe:1',
    '-nostats',
    ...args,
  ], runInShell: false);
  void stop() => process.kill();
  cancellation?.addListener(stop);
  final errors = process.stderr.transform(utf8.decoder).join();
  final progress = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        if (expectedDuration == null ||
            expectedDuration <= Duration.zero ||
            !line.startsWith('out_time_us=')) {
          return;
        }
        final micros = int.tryParse(line.substring('out_time_us='.length));
        if (micros != null) {
          onProgress?.call(
            (micros / expectedDuration.inMicroseconds).clamp(0.0, 1.0),
          );
        }
      });
  final progressDone = progress.asFuture<void>();
  final exitCode = await process.exitCode;
  await progressDone;
  final stderr = await errors;
  cancellation?.removeListener(stop);
  cancellation?.throwIfCancelled();
  if (exitCode != 0) {
    throw ProcessException('ffmpeg', args, stderr, exitCode);
  }
}

Future<void> _runAndroidFfmpeg(
  List<String> args, {
  Duration? expectedDuration,
  void Function(double progress)? onProgress,
  RenderCancellation? cancellation,
}) async {
  cancellation?.throwIfCancelled();
  await FFmpegKitExtended.initialize();
  cancellation?.throwIfCancelled();
  final session = FFmpegKit.createSessionFromArguments(args);
  void stop() => FFmpegKit.cancel(session);
  cancellation?.addListener(stop);
  cancellation?.throwIfCancelled();
  session.setExpectedTranscodingDuration(expectedDuration);
  session.setStatisticsCallback((statistics) {
    final progress =
        statistics.transcodingProgress ??
        session.calculateTranscodingProgress(statistics.time);
    if (progress != null) {
      onProgress?.call(progress);
    }
  });
  try {
    await session.executeAsync();
  } finally {
    cancellation?.removeListener(stop);
  }
  cancellation?.throwIfCancelled();
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
  required int frameRate,
  required String? titlePath,
  required String? subtitlePath,
  required CaptionLayout captionLayout,
  required String? fontPath,
}) {
  final captionTiming = clip.captionSettings.timingFor(clip.end - clip.start);
  final captionStart =
      captionTiming.startMicroseconds / Duration.microsecondsPerSecond;
  final captionEnd =
      captionTiming.endMicroseconds / Duration.microsecondsPerSecond;
  final enable = "enable='gte(t,$captionStart)*lt(t,$captionEnd)'";
  final filters = <String>[
    _imageFilter(clip: clip, template: template, width: width, height: height),
    ..._motionFilters(
      motion: clip.motionFor(template),
      focalX: clip.cropTransform.focalX,
      focalY: clip.cropTransform.focalY,
      duration: clip.end - clip.start,
      width: width,
      height: height,
      frameRate: frameRate,
    ),
    ..._frameFilters(template: template, width: width, height: height),
    if (titlePath != null || subtitlePath != null)
      for (final overlay in _overlayFilters(
        template: template,
        width: width,
        height: height,
      ))
        '$overlay:$enable',
    ..._textFilters(
      clip: clip,
      layout: captionLayout,
      timing: captionTiming,
      enable: enable,
      fontPath: fontPath,
      titlePath: titlePath,
      subtitlePath: subtitlePath,
    ),
  ];

  return filters.join(',');
}

List<String> _motionFilters({
  required ClipMotion motion,
  required double focalX,
  required double focalY,
  required Duration duration,
  required int width,
  required int height,
  required int frameRate,
}) {
  if (motion.preset == ClipMotionPreset.none) return const [];
  final frames = FrameTimeQuantizer(frameRate).frameCountForDuration(duration);
  final progress = 'min(on/${frames - 1 > 0 ? frames - 1 : 1},1)';
  final zoom =
      '${motion.startZoom}+(${motion.endZoom - motion.startZoom})*$progress';
  final startAnchor = motion.horizontalAnchorAt(0, focalX);
  final endAnchor = motion.horizontalAnchorAt(1, focalX);
  final xAnchor = '$startAnchor+(${endAnchor - startAnchor})*$progress';
  final yAnchor = ((focalY + 1) / 2).clamp(0.0, 1.0);
  return [
    "zoompan=z='$zoom':x='(iw-iw/zoom)*($xAnchor)':y='(ih-ih/zoom)*$yAnchor':d=1:s=${width}x$height:fps=$frameRate",
  ];
}

String _imageFilter({
  required MediaTrackClipPayload clip,
  required VideoTemplate template,
  required int width,
  required int height,
}) {
  if (clip.imageFit == VideoTemplateImageFit.cover) {
    final crop = clip.cropTransform;
    final scaledWidth = (width * crop.zoom).round();
    final scaledHeight = (height * crop.zoom).round();
    final cropX = ((crop.focalX + 1) / 2).toStringAsFixed(6);
    final cropY = ((crop.focalY + 1) / 2).toStringAsFixed(6);
    return [
      'scale=w=$scaledWidth:h=$scaledHeight:force_original_aspect_ratio=increase:flags=bilinear',
      "crop=$width:$height:x='(iw-ow)*$cropX':y='(ih-oh)*$cropY':exact=1",
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
  required MediaTrackClipPayload clip,
  required CaptionLayout layout,
  required CaptionTiming timing,
  required String enable,
  required String? fontPath,
  required String? titlePath,
  required String? subtitlePath,
}) {
  final settings = clip.captionSettings;
  final start = timing.startMicroseconds / Duration.microsecondsPerSecond;
  final entrance = timing.entranceMicroseconds / Duration.microsecondsPerSecond;
  final progress = "min(max((t-$start)/$entrance,0),1)";
  final alpha = settings.entrance == CaptionEntrance.fade ? progress : '1';
  final offset = settings.entrance == CaptionEntrance.slide
      ? '+${layout.height ~/ 30}*(1-$progress)'
      : '';
  String filter(String path, int size, int top, int spacing) =>
      "drawtext=${fontPath == null ? '' : "fontfile='${_escapeFilterPath(fontPath)}':"}textfile='${_escapeFilterPath(path)}':expansion=none:x='(w-text_w)/2':y='$top$offset':fontsize=$size:fontcolor=white:line_spacing=$spacing:box=1:boxcolor=black@0.75:boxborderw=${(size / 5).round()}:alpha='$alpha':$enable";
  final filters = <String>[
    if (titlePath != null)
      filter(titlePath, layout.titleSize, layout.top, layout.titleLineSpacing),
  ];

  if (subtitlePath != null) {
    filters.add(
      filter(
        subtitlePath,
        layout.supportSize,
        layout.supportTop,
        layout.supportLineSpacing,
      ),
    );
  }

  return filters;
}

String _escapeFilterPath(String value) {
  return value
      .replaceAll(r'\', '/')
      .replaceAll(':', r'\:')
      .replaceAll("'", r"'\''");
}

double _durationSeconds(MediaTrackClipPayload clip) {
  final duration = clip.end - clip.start;
  final safeDuration = duration > Duration.zero
      ? duration
      : const Duration(milliseconds: 500);
  return safeDuration.inMicroseconds / Duration.microsecondsPerSecond;
}

String _buildSignature(
  BuildPreviewVideoRequest request,
  List<String> segmentVideoArgs,
  String? rendererVersion,
  String? fontSignature,
  Map<String, String> sourceFingerprints,
) {
  return _stableHexKey([
    request.projectId,
    rendererVersion,
    fontSignature,
    _templateSignature(request.template),
    request.audioSourcePath ?? 'no-audio',
    request.audioMix.toJson(),
    request.audioSourceDuration?.inMicroseconds,
    '${request.width}x${request.height}',
    '${request.frameRate}',
    segmentVideoArgs.join(' '),
    request.audioSourcePath == null
        ? null
        : sourceFingerprints[request.audioSourcePath],
    for (final clip in request.resolvedClips)
      '${clip.mediaId}:${clip.start.inMicroseconds}:${clip.end.inMicroseconds}:${clip.caption}:${clip.captionSupportingLine}:${clip.captionSettings.toJson()}:${clip.sourcePath}:${clip.imageFit.name}:${clip.cropTransform.focalX}:${clip.cropTransform.focalY}:${clip.cropTransform.zoom}:${clip.motionOverride?.name}:${clip.motionIntensity.name}:${clip.useStyleMotionIntensity}:${clip.transitionOverride?.name}:${clip.transitionDuration.inMicroseconds}',
    for (final clip in request.resolvedClips)
      sourceFingerprints[clip.sourcePath],
  ]);
}

String _previewClipCacheKey({
  required MediaTrackClipPayload clip,
  required FileStat sourceStat,
  required String sourceFingerprint,
  required int width,
  required int height,
  required int frameRate,
  required VideoTemplate template,
  required List<String> segmentVideoArgs,
  required String? fontPath,
  required String? fontSignature,
  required String? rendererVersion,
}) {
  return _stableHexKey([
    'motion-caption-source-content-v6',
    clip.mediaId,
    clip.caption,
    clip.captionSupportingLine,
    clip.captionSettings.toJson(),
    clip.sourcePath,
    clip.imageFit.name,
    clip.cropTransform.focalX,
    clip.cropTransform.focalY,
    clip.cropTransform.zoom,
    clip.motionOverride?.name,
    clip.motionIntensity.name,
    clip.useStyleMotionIntensity,
    clip.start.inMicroseconds,
    clip.end.inMicroseconds,
    sourceStat.size,
    sourceStat.modified.millisecondsSinceEpoch,
    sourceFingerprint,
    _templateSignature(template),
    width,
    height,
    frameRate,
    segmentVideoArgs.join(' '),
    fontPath,
    fontSignature,
    rendererVersion,
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
  return sha256.convert(utf8.encode(parts.join('|'))).toString();
}
