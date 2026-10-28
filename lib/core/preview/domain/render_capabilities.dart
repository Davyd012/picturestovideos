import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/domain/clip_motion.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';

enum RenderCapabilityIssue {
  unsupportedPlatform,
  missingFfmpeg,
  probeFailed,
  missingFilter,
  missingEncoder,
  missingMuxer,
  missingFont,
}

class RenderCapabilityException implements Exception {
  const RenderCapabilityException(this.issue, {this.detail});

  final RenderCapabilityIssue issue;
  final String? detail;

  @override
  String toString() =>
      'Render capability unavailable: ${issue.name}${detail == null ? '' : ' ($detail)'}';
}

class RenderCapabilities {
  RenderCapabilities({
    required this.platformSupported,
    required this.ffmpegAvailable,
    required this.filters,
    required this.encoders,
    required this.muxers,
    required this.videoEncoder,
    this.fontPath,
    this.fontSignature,
    this.version,
    this.diagnostic,
  });

  final bool platformSupported;
  final bool ffmpegAvailable;
  final Set<String> filters;
  final Set<String> encoders;
  final Set<String> muxers;
  final String videoEncoder;
  final String? fontPath;
  final String? fontSignature;
  final String? version;
  final String? diagnostic;

  bool supportsFilter(String filter) =>
      platformSupported && ffmpegAvailable && filters.contains(filter);

  bool get supportsMotion => supportsFilter('zoompan');
  bool get supportsTransitions => supportsFilter('xfade');
  bool get supportsCaptions =>
      supportsFilter('drawtext') && (fontPath?.isNotEmpty ?? false);

  bool supportsTemplate(VideoTemplate template, {required int clipCount}) {
    if (!platformSupported || !ffmpegAvailable) return false;
    final requiredFilters = <String>{'scale'};
    requiredFilters.add(
      template.imageFit == VideoTemplateImageFit.cover ? 'crop' : 'pad',
    );
    if (template.imageAnimation != VideoTemplateImageAnimation.none) {
      requiredFilters.add('zoompan');
    }
    if (template.frameStyle != VideoTemplateFrameStyle.none ||
        template.overlayStyle != VideoTemplateOverlayStyle.none) {
      requiredFilters.add('drawbox');
    }
    if (clipCount > 1 &&
        template.transition != VideoTemplateTransition.hardCut) {
      requiredFilters.add('xfade');
    }
    return filters.containsAll(requiredFilters);
  }

  List<RenderCapabilityIssue> issuesFor(VideoComposition composition) {
    if (!platformSupported) {
      return const [RenderCapabilityIssue.unsupportedPlatform];
    }
    if (!ffmpegAvailable) return const [RenderCapabilityIssue.missingFfmpeg];

    final required = _requirementsFor(composition);
    if (required.fontRequired && (fontPath == null || fontPath!.isEmpty)) {
      return const [RenderCapabilityIssue.missingFont];
    }
    if (!filters.containsAll(required.filters)) {
      return const [RenderCapabilityIssue.missingFilter];
    }
    if (!encoders.containsAll(required.encoders)) {
      return const [RenderCapabilityIssue.missingEncoder];
    }
    if (!muxers.containsAll(required.muxers)) {
      return const [RenderCapabilityIssue.missingMuxer];
    }
    return const [];
  }

  ({
    Set<String> filters,
    Set<String> encoders,
    Set<String> muxers,
    bool fontRequired,
  })
  _requirementsFor(VideoComposition composition) {
    final requiredFilters = <String>{'scale'};
    for (final clip in composition.clips) {
      requiredFilters.add(
        clip.imageFit == VideoTemplateImageFit.cover ? 'crop' : 'pad',
      );
    }
    final requiredEncoders = <String>{videoEncoder};
    const requiredMuxers = <String>{'mp4'};
    if (composition.audioSourcePath?.isNotEmpty ?? false) {
      requiredFilters.addAll({'atrim', 'asetpts', 'apad'});
      if (composition.audioMix.fadeIn > Duration.zero ||
          composition.audioMix.fadeOut > Duration.zero) {
        requiredFilters.add('afade');
      }
      requiredEncoders.add('aac');
    }
    if (composition.clips.any(
      (clip) => clip.motion.preset != ClipMotionPreset.none,
    )) {
      requiredFilters.add('zoompan');
    }
    if (composition.clips.length > 1 &&
        composition.clips
            .take(composition.clips.length - 1)
            .any(
              (clip) =>
                  clip.transitionType != ClipTransitionType.cut &&
                  clip.transitionDuration > Duration.zero,
            )) {
      requiredFilters.add('xfade');
    }
    final hasCaptions = composition.clips.any(
      (clip) =>
          clip.caption.isNotEmpty || clip.captionSupportingLine.isNotEmpty,
    );
    if (hasCaptions) {
      requiredFilters.add('drawtext');
    }
    if (composition.template.frameStyle != VideoTemplateFrameStyle.none ||
        (hasCaptions &&
            composition.template.overlayStyle !=
                VideoTemplateOverlayStyle.none)) {
      requiredFilters.add('drawbox');
    }

    return (
      filters: requiredFilters,
      encoders: requiredEncoders,
      muxers: requiredMuxers,
      fontRequired: hasCaptions,
    );
  }

  void requireFor(VideoComposition composition) {
    final issues = issuesFor(composition);
    if (issues.isNotEmpty) {
      final issue = issues.first;
      final required = _requirementsFor(composition);
      final detail = switch (issue) {
        RenderCapabilityIssue.missingFilter =>
          'Missing filters: ${required.filters.difference(filters).join(', ')}',
        RenderCapabilityIssue.missingEncoder =>
          'Missing encoders: ${required.encoders.difference(encoders).join(', ')}',
        RenderCapabilityIssue.missingMuxer =>
          'Missing muxers: ${required.muxers.difference(muxers).join(', ')}',
        _ => diagnostic,
      };
      throw RenderCapabilityException(issue, detail: detail);
    }
  }
}

enum FfmpegCapabilityListKind { filters, encoders, muxers }

Set<String> parseFfmpegCapabilityList(
  String output, {
  required FfmpegCapabilityListKind kind,
}) {
  final values = <String>{};
  for (final line in output.split('\n')) {
    final fields = line.trim().split(RegExp(r'\s+'));
    for (var index = 0; index + 1 < fields.length; index++) {
      final flags = fields[index];
      final matches = switch (kind) {
        FfmpegCapabilityListKind.filters => RegExp(
          r'^[TSC.]{3}$',
        ).hasMatch(flags),
        FfmpegCapabilityListKind.encoders => RegExp(
          r'^[A-Z.]{6}$',
        ).hasMatch(flags),
        FfmpegCapabilityListKind.muxers => flags == 'E',
      };
      if (!matches) continue;
      for (final name in fields[index + 1].split(',')) {
        if (RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) values.add(name);
      }
    }
  }
  return Set.unmodifiable(values);
}
