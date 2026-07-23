import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/timeline/application/resolve_media_track_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class TimelineTabView extends StatelessWidget {
  const TimelineTabView({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.timelineScale,
    required this.selectedMedia,
    required this.events,
    required this.onTimelineScaleChanged,
    required this.onCurrentPointChanged,
    this.audioDuration,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final double timelineScale;
  final List<LibraryMediaItem> selectedMedia;
  final List<BeatEvent> events;
  final ValueChanged<double> onTimelineScaleChanged;
  final ValueChanged<Duration> onCurrentPointChanged;
  final Duration? audioDuration;

  @override
  Widget build(BuildContext context) {
    final markers = _markers;
    final clips = _clips;
    final duration = _duration(markers, clips, audioDuration);
    final nextIndex = playback?.nextBeatIndex ?? 0;
    final scale = timelineScale
        .clamp(_minTimelineScale, _maxTimelineScale)
        .toDouble();
    final trackWidth = _baseTrackWidth * scale;
    final timelineWidth = _trackStartOffset + trackWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${markers.length} markers')),
            Chip(label: Text('${selectedMedia.length} queued')),
            Chip(label: Text(_bpmLabel)),
            Chip(label: Text('Next $nextIndex')),
            Chip(label: Text('${scale.toStringAsFixed(1)}x timeline')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Timeline', style: context.textTheme.titleMedium),
            const Spacer(),
            Icon(Icons.zoom_out, color: context.colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: scale,
                min: _minTimelineScale,
                max: _maxTimelineScale,
                divisions: 9,
                onChanged: onTimelineScaleChanged,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.zoom_in, color: context.colors.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  onCurrentPointChanged(
                    _timeForPosition(
                      position: details.localPosition.dx - _trackStartOffset,
                      duration: duration,
                      width: trackWidth,
                    ),
                  );
                },
                child: SizedBox(
                  width: timelineWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TrackHeader(label: _formatDuration(duration)),
                      const SizedBox(height: 8),
                      _ImageTrack(
                        clips: clips,
                        duration: duration,
                        trackWidth: trackWidth,
                      ),
                      const SizedBox(height: 12),
                      _AudioTrack(
                        markers: markers,
                        duration: duration,
                        trackWidth: trackWidth,
                      ),
                      const SizedBox(height: 12),
                      _MarkerTrack(
                        markers: markers,
                        duration: duration,
                        trackWidth: trackWidth,
                      ),
                      PositionedPlayhead(
                        currentTime: playback?.currentTime ?? Duration.zero,
                        duration: duration,
                        trackWidth: trackWidth,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const double _minTimelineScale = 0.75;
  static const double _maxTimelineScale = 3;
  static const double _baseTrackWidth = 600;
  static const double _trackLabelWidth = 96;
  static const double _trackGap = 12;
  static const double _trackStartOffset = _trackLabelWidth + _trackGap;

  List<Beat> get _markers {
    final resolvedProject = project;
    if (resolvedProject != null) {
      final projectMarkers = _projectMarkerEvents(resolvedProject);
      return [
        for (final event in projectMarkers) Beat(time: event.time, strength: 1),
      ];
    }
    if (events.isNotEmpty) {
      return [for (final event in events) Beat(time: event.time, strength: 1)];
    }
    if (beatMap?.beats.isNotEmpty ?? false) {
      return beatMap!.beats;
    }
    return const [
      Beat(time: Duration(seconds: 1), strength: 0.8),
      Beat(time: Duration(seconds: 4), strength: 1),
      Beat(time: Duration(seconds: 7), strength: 0.7),
      Beat(time: Duration(seconds: 11), strength: 0.9),
      Beat(time: Duration(seconds: 15), strength: 0.8),
    ];
  }

  List<BeatEvent> _projectMarkerEvents(ProjectTimeline project) {
    for (final track in project.tracks) {
      if (track.id == 'track-markers') {
        return track.events;
      }
    }
    return const [];
  }

  List<MediaTrackClipPayload> get _clips {
    final resolvedProject = project;
    final resolvedBeatMap = beatMap ?? resolvedProject?.beatMap;
    if (resolvedBeatMap != null) {
      final clips = const ResolveMediaTrackClipsUseCase().call(
        beatMap: resolvedBeatMap,
        project: resolvedProject,
      );
      if (clips.isNotEmpty) {
        return clips;
      }
    }
    if (resolvedProject != null) {
      return const [];
    }
    return const [
      MediaTrackClipPayload(
        mediaId: 'sample-01',
        title: 'IMG_1042.jpg',
        tagline: 'Opening frame',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      ),
      MediaTrackClipPayload(
        mediaId: 'sample-02',
        title: 'IMG_1088.jpg',
        tagline: 'Beat cut',
        start: Duration(seconds: 3),
        end: Duration(seconds: 6),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      ),
      MediaTrackClipPayload(
        mediaId: 'sample-03',
        title: 'IMG_1130.jpg',
        tagline: 'Memory beat',
        start: Duration(seconds: 6),
        end: Duration(seconds: 9),
        sourcePath: '',
        imageFit: VideoTemplateImageFit.cover,
      ),
    ];
  }

  String get _bpmLabel {
    final bpm = beatMap?.bpm ?? project?.beatMap.bpm;
    if (bpm == null || bpm == 0) {
      return '19.6 BPM';
    }
    return '${bpm.toStringAsFixed(1)} BPM';
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Images', style: context.textTheme.labelLarge),
        const Spacer(),
        Text(label, style: context.textTheme.labelMedium),
      ],
    );
  }
}

class _ImageTrack extends StatelessWidget {
  const _ImageTrack({
    required this.clips,
    required this.duration,
    required this.trackWidth,
  });

  final List<MediaTrackClipPayload> clips;
  final Duration duration;
  final double trackWidth;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Images',
      icon: Icons.photo_library_outlined,
      trackWidth: trackWidth,
      child: Stack(
        children: [
          for (final clip in clips)
            Positioned(
              left: _positionForTime(clip.start, duration, trackWidth),
              width: _widthForClip(clip, duration, trackWidth),
              top: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  clip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioTrack extends StatelessWidget {
  const _AudioTrack({
    required this.markers,
    required this.duration,
    required this.trackWidth,
  });

  final List<Beat> markers;
  final Duration duration;
  final double trackWidth;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Audio',
      icon: Icons.graphic_eq_outlined,
      trackWidth: trackWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final marker in markers.take(40))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 16 + marker.strength.clamp(0, 1) * 32,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerTrack extends StatelessWidget {
  const _MarkerTrack({
    required this.markers,
    required this.duration,
    required this.trackWidth,
  });

  final List<Beat> markers;
  final Duration duration;
  final double trackWidth;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Markers',
      icon: Icons.location_on_outlined,
      trackWidth: trackWidth,
      child: Stack(
        children: [
          for (var index = 0; index < markers.length; index++)
            Positioned(
              left: _positionForTime(markers[index].time, duration, trackWidth),
              top: 10,
              bottom: 10,
              child: Column(
                children: [
                  Expanded(
                    child: Container(width: 2, color: context.colors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('B${index + 1}', style: context.textTheme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackShell extends StatelessWidget {
  const _TrackShell({
    required this.label,
    required this.icon,
    required this.trackWidth,
    required this.child,
  });

  final String label;
  final IconData icon;
  final double trackWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        children: [
          SizedBox(
            width: TimelineTabView._trackLabelWidth,
            child: Row(
              children: [
                Icon(icon, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: context.textTheme.labelLarge),
                ),
              ],
            ),
          ),
          const SizedBox(width: TimelineTabView._trackGap),
          SizedBox(
            width: trackWidth,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class PositionedPlayhead extends StatelessWidget {
  const PositionedPlayhead({
    required this.currentTime,
    required this.duration,
    required this.trackWidth,
    super.key,
  });

  final Duration currentTime;
  final Duration duration;
  final double trackWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left:
                TimelineTabView._trackStartOffset +
                _positionForTime(currentTime, duration, trackWidth),
            bottom: 0,
            child: Container(
              width: 2,
              height: 300,
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

Duration _duration(
  List<Beat> markers,
  List<MediaTrackClipPayload> clips,
  Duration? audioDuration,
) {
  var duration = audioDuration != null && audioDuration > Duration.zero
      ? audioDuration
      : Duration.zero;
  for (final marker in markers) {
    if (marker.time > duration) {
      duration = marker.time;
    }
  }
  for (final clip in clips) {
    if (clip.end > duration) {
      duration = clip.end;
    }
  }
  return duration > Duration.zero ? duration : const Duration(seconds: 30);
}

Duration _timeForPosition({
  required double position,
  required Duration duration,
  required double width,
}) {
  final clampedPosition = position.clamp(0, width).toDouble();
  return Duration(
    milliseconds: (duration.inMilliseconds * clampedPosition / width).round(),
  );
}

double _positionForTime(Duration time, Duration duration, double trackWidth) {
  if (duration <= Duration.zero) {
    return 0;
  }
  final ratio = time.inMilliseconds / duration.inMilliseconds;
  final clampedRatio = ratio.clamp(0, 1).toDouble();
  return trackWidth * clampedRatio;
}

double _widthForClip(
  MediaTrackClipPayload clip,
  Duration duration,
  double trackWidth,
) {
  final width =
      _positionForTime(clip.end, duration, trackWidth) -
      _positionForTime(clip.start, duration, trackWidth);
  return width.clamp(48, 260).toDouble();
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
