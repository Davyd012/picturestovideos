import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/domain/caption_layout.dart';
import 'package:picturestovideos/core/composition/domain/frame_time_quantizer.dart';
import 'package:picturestovideos/core/preview/domain/caption_settings.dart';
import 'package:picturestovideos/core/preview/domain/clip_transition.dart';

class CompositionLayer {
  const CompositionLayer({
    required this.clip,
    required this.progress,
    required this.motionZoom,
    required this.horizontalAnchor,
    required this.captionFrame,
    required this.captionLayout,
  });
  final CompositionClip clip;
  final double progress;
  final double motionZoom;
  final double horizontalAnchor;
  final CaptionFrame captionFrame;
  final CaptionLayout captionLayout;
}

class EvaluatedCompositionFrame {
  const EvaluatedCompositionFrame({
    required this.time,
    required this.layers,
    required this.transitionProgress,
    required this.audioGain,
  });
  final Duration time;

  /// Draw order: outgoing first, incoming last.
  final List<CompositionLayer> layers;
  final double transitionProgress;
  final double audioGain;

  bool get isTransition => layers.length == 2;
}

class CompositionEvaluator {
  const CompositionEvaluator();

  EvaluatedCompositionFrame evaluate(
    VideoComposition composition,
    Duration requestedTime,
  ) {
    final resolvedComposition = composition.quantizedForOutput();
    final time = FrameTimeQuantizer(resolvedComposition.frameRate)
        .quantize(requestedTime);
    final clips = resolvedComposition.clips;
    final transitions = transitionsFor(resolvedComposition);
    if (clips.isEmpty ||
        time < Duration.zero ||
        time >= resolvedComposition.duration) {
      return EvaluatedCompositionFrame(
        time: time,
        layers: const [],
        transitionProgress: 0,
        audioGain: 0,
      );
    }

    for (var index = 0; index + 1 < clips.length; index++) {
      final outgoing = clips[index];
      final incoming = clips[index + 1];
      if (outgoing.end != incoming.start) continue;
      final transition = transitions[index];
      if (transition.duration <= Duration.zero ||
          time < transition.start ||
          time >= transition.end) {
        continue;
      }
      final progress = transition.progressAt(time);
      return EvaluatedCompositionFrame(
        time: time,
        layers: List.unmodifiable([
          _layer(outgoing, time, resolvedComposition),
          _layer(incoming, time, resolvedComposition),
        ]),
        transitionProgress: progress,
        audioGain: resolvedComposition.audioMix.volumeAt(
          time,
          sourceDuration: resolvedComposition.audioSourceDuration,
          videoDuration: resolvedComposition.duration,
        ),
      );
    }

    // Half-open intervals give an exact cut to the incoming clip. Gaps hold
    // the prior still; before the first clip, hold the first still.
    var selected = clips.first;
    for (final clip in clips) {
      if (time >= clip.start && time < clip.end) {
        selected = clip;
        break;
      }
      if (clip.start <= time) selected = clip;
    }
    return EvaluatedCompositionFrame(
      time: time,
      layers: List.unmodifiable([_layer(selected, time, resolvedComposition)]),
      transitionProgress: 0,
      audioGain: resolvedComposition.audioMix.volumeAt(
        time,
        sourceDuration: resolvedComposition.audioSourceDuration,
        videoDuration: resolvedComposition.duration,
      ),
    );
  }

  CompositionLayer _layer(
    CompositionClip clip,
    Duration time,
    VideoComposition composition,
  ) {
    final progress = FrameTimeQuantizer(composition.frameRate)
        .progressForFrame(time: time, start: clip.start, end: clip.end);
    return CompositionLayer(
      clip: clip,
      progress: progress,
      motionZoom: clip.motion.zoomAt(progress),
      horizontalAnchor: clip.motion.horizontalAnchorAt(
        progress,
        clip.cropTransform.focalX,
      ),
      captionFrame: clip.captionSettings.evaluate(
        time - clip.start,
        clip.end - clip.start,
      ),
      captionLayout: captionLayoutFor(clip, composition),
    );
  }

  CaptionLayout captionLayoutFor(
    CompositionClip clip,
    VideoComposition composition,
  ) => CaptionLayout(
    title: clip.caption,
    supportingLine: clip.captionSupportingLine,
    template: composition.template,
    settings: clip.captionSettings,
    width: composition.width,
    height: composition.height,
  );

  List<ClipTransition> transitionsFor(VideoComposition composition) {
    final resolvedComposition = composition.quantizedForOutput();
    return List.unmodifiable([
      for (var index = 0; index + 1 < resolvedComposition.clips.length; index++)
        ClipTransition.between(
          resolvedComposition.clips[index].toPayload(),
          resolvedComposition.clips[index + 1].toPayload(),
          resolvedComposition.template,
        ),
    ]);
  }
}
