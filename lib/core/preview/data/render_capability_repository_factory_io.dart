import 'dart:io';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';

RenderCapabilityRepository createRenderCapabilityRepository() =>
    const IoRenderCapabilityRepository();

class IoRenderCapabilityRepository implements RenderCapabilityRepository {
  const IoRenderCapabilityRepository();

  @override
  Future<RenderCapabilities> probe() async {
    final isAndroid = Platform.isAndroid;
    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    if (!isAndroid && !isDesktop) {
      return RenderCapabilities(
        platformSupported: false,
        ffmpegAvailable: false,
        filters: const {},
        encoders: const {},
        muxers: const {},
        videoEncoder: '',
      );
    }

    try {
      if (isAndroid) {
        await FFmpegKitExtended.initialize();
        final font = await _fontInfo();
        return RenderCapabilities(
          platformSupported: true,
          ffmpegAvailable: true,
          filters: _registeredNames(FFmpegKitExtended.getRegisteredFilters()),
          encoders: _registeredNames(FFmpegKitExtended.getRegisteredEncoders()),
          muxers: _registeredNames(FFmpegKitExtended.getRegisteredMuxers()),
          videoEncoder: 'mpeg4',
          fontPath: font?.path,
          fontSignature: font?.signature,
          version: FFmpegKitConfig.getFFmpegVersion(),
        );
      }
      final version = await _run(const ['-version']);
      final filters = await _run(const ['-hide_banner', '-filters']);
      final encoders = await _run(const ['-hide_banner', '-encoders']);
      final muxers = await _run(const ['-hide_banner', '-muxers']);
      final font = await _fontInfo();
      return RenderCapabilities(
        platformSupported: true,
        ffmpegAvailable: true,
        filters: parseFfmpegCapabilityList(
          filters,
          kind: FfmpegCapabilityListKind.filters,
        ),
        encoders: parseFfmpegCapabilityList(
          encoders,
          kind: FfmpegCapabilityListKind.encoders,
        ),
        muxers: parseFfmpegCapabilityList(
          muxers,
          kind: FfmpegCapabilityListKind.muxers,
        ),
        videoEncoder: 'libx264',
        fontPath: font?.path,
        fontSignature: font?.signature,
        version: version.split('\n').first.trim(),
      );
    } on ProcessException catch (error) {
      if (!isAndroid && error.errorCode == 2) {
        return RenderCapabilities(
          platformSupported: true,
          ffmpegAvailable: false,
          filters: const {},
          encoders: const {},
          muxers: const {},
          videoEncoder: 'libx264',
          diagnostic: error.message,
        );
      }
      throw RenderCapabilityException(
        RenderCapabilityIssue.probeFailed,
        detail: error.message,
      );
    } on RenderCapabilityException {
      rethrow;
    } catch (error) {
      throw RenderCapabilityException(
        RenderCapabilityIssue.probeFailed,
        detail: error.toString(),
      );
    }
  }

  Future<String> _run(List<String> arguments) async {
    final result = await Process.run('ffmpeg', arguments, runInShell: false);
    if (result.exitCode != 0) {
      throw RenderCapabilityException(
        RenderCapabilityIssue.probeFailed,
        detail: result.stderr.toString(),
      );
    }
    return '${result.stdout}\n${result.stderr}';
  }

  Set<String> _registeredNames(String names) => Set.unmodifiable(
    names
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty),
  );

  Future<_FontInfo?> _fontInfo() async {
    final windowsRoot = Platform.environment['WINDIR'] ?? r'C:\Windows';
    final candidates = <String>[
      if (Platform.isAndroid) '/system/fonts/Roboto-Regular.ttf',
      if (Platform.isWindows) '$windowsRoot\\Fonts\\arial.ttf',
      if (Platform.isWindows) '$windowsRoot\\Fonts\\segoeui.ttf',
      if (Platform.isMacOS) '/System/Library/Fonts/Supplemental/Arial.ttf',
      if (Platform.isLinux) '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
      if (Platform.isLinux)
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
      if (Platform.isLinux)
        '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (!await file.exists()) continue;
      final stat = await file.stat();
      return _FontInfo(
        path: path,
        signature: '${stat.size}:${stat.modified.millisecondsSinceEpoch}',
      );
    }
    return null;
  }
}

class _FontInfo {
  const _FontInfo({required this.path, required this.signature});

  final String path;
  final String signature;
}
