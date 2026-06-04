import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
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
    required this.selectedMedia,
    required this.events,
    required this.onCurrentPointChanged,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final List<LibraryMediaItem> selectedMedia;
  final List<BeatEvent> events;
  final ValueChanged<Duration> onCurrentPointChanged;

  @override
  Widget build(BuildContext context) {
    final markers = _markers;
    final clips = _clips;
    final duration = _duration(markers, clips);
    final nextIndex = playback?.nextBeatIndex ?? 0;

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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Timeline', style: context.textTheme.titleMedium),
            const Spacer(),
            Icon(Icons.zoom_out, color: context.colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Slider(value: 0.5, onChanged: null)),
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
                      position: details.localPosition.dx,
                      duration: duration,
                      width: _timelineWidth,
                    ),
                  );
                },
                child: SizedBox(
                  width: _timelineWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TrackHeader(label: _formatDuration(duration)),
                      const SizedBox(height: 8),
                      _ImageTrack(clips: clips, duration: duration),
                      const SizedBox(height: 12),
                      _AudioTrack(markers: markers, duration: duration),
                      const SizedBox(height: 12),
                      _MarkerTrack(markers: markers, duration: duration),
                      PositionedPlayhead(
                        currentTime: playback?.currentTime ?? Duration.zero,
                        duration: duration,
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

  static const double _timelineWidth = 720;

  List<Beat> get _markers {
    final projectMarkers = _projectMarkerEvents;
    if (projectMarkers.isNotEmpty) {
      return [
        for (final event in projectMarkers) Beat(time: event.time, strength: 1),
      ];
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

  List<BeatEvent> get _projectMarkerEvents {
    final tracks = project?.tracks ?? const [];
    for (final track in tracks) {
      if (track.id == 'track-markers') {
        return track.events;
      }
    }
    return events;
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
    return const [
      MediaTrackClipPayload(
        mediaId: 'sample-01',
        title: 'IMG_1042.jpg',
        tagline: 'Opening frame',
        start: Duration.zero,
        end: Duration(seconds: 3),
        sourcePath: '',
      ),
      MediaTrackClipPayload(
        mediaId: 'sample-02',
        title: 'IMG_1088.jpg',
        tagline: 'Beat cut',
        start: Duration(seconds: 3),
        end: Duration(seconds: 6),
        sourcePath: '',
      ),
      MediaTrackClipPayload(
        mediaId: 'sample-03',
        title: 'IMG_1130.jpg',
        tagline: 'Memory beat',
        start: Duration(seconds: 6),
        end: Duration(seconds: 9),
        sourcePath: '',
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
  const _ImageTrack({required this.clips, required this.duration});

  final List<MediaTrackClipPayload> clips;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Images',
      icon: Icons.photo_library_outlined,
      child: Stack(
        children: [
          for (final clip in clips)
            Positioned(
              left: _positionForTime(clip.start, duration),
              width: _widthForClip(clip, duration),
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
  const _AudioTrack({required this.markers, required this.duration});

  final List<Beat> markers;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Audio',
      icon: Icons.graphic_eq_outlined,
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
  const _MarkerTrack({required this.markers, required this.duration});

  final List<Beat> markers;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return _TrackShell(
      label: 'Markers',
      icon: Icons.location_on_outlined,
      child: Stack(
        children: [
          for (var index = 0; index < markers.length; index++)
            Positioned(
              left: _positionForTime(markers[index].time, duration),
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
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        children: [
          SizedBox(
            width: 96,
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
          const SizedBox(width: 12),
          Expanded(
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
    super.key,
  });

  final Duration currentTime;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 108 + _positionForTime(currentTime, duration),
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

Duration _duration(List<Beat> markers, List<MediaTrackClipPayload> clips) {
  var duration = const Duration(seconds: 30);
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
  return duration;
}

Duration _timeForPosition({
  required double position,
  required Duration duration,
  required double width,
}) {
  final clampedPosition = position.clamp(0, width) as double;
  return Duration(
    milliseconds: (duration.inMilliseconds * clampedPosition / width).round(),
  );
}

double _positionForTime(Duration time, Duration duration) {
  if (duration <= Duration.zero) {
    return 0;
  }
  final ratio = time.inMilliseconds / duration.inMilliseconds;
  return 600 * ratio.clamp(0, 1);
}

double _widthForClip(MediaTrackClipPayload clip, Duration duration) {
  final width =
      _positionForTime(clip.end, duration) -
      _positionForTime(clip.start, duration);
  return width.clamp(88, 220);
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
