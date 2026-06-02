import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picturestovideos/core/audio/domain/beat.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/resolve_media_track_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class EditorTimelineWorkspace extends StatefulWidget {
  const EditorTimelineWorkspace({
    super.key,
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.selectedMedia,
    required this.selectedMarker,
    required this.audioDuration,
    required this.onCurrentPointChanged,
    required this.onAddMarker,
    required this.onAddManualImagePoint,
    required this.onDeleteSelectedMarker,
    required this.onMarkerSelected,
    required this.onMarkerSelectionCleared,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final List<LibraryMediaItem> selectedMedia;
  final TimelineMarkerSelection? selectedMarker;
  final Duration? audioDuration;
  final ValueChanged<Duration> onCurrentPointChanged;
  final VoidCallback onAddMarker;
  final VoidCallback onAddManualImagePoint;
  final VoidCallback onDeleteSelectedMarker;
  final ValueChanged<TimelineMarkerSelection> onMarkerSelected;
  final VoidCallback onMarkerSelectionCleared;

  static const double _laneLabelWidth = 104;
  static const double _timelineScaleHeight = 28;
  static const double _clipLaneHeight = 84;
  static const double _audioLaneHeight = 72;
  static const double _timelineGap = 16;
  static const double _beatWidth = 56;
  static const int _maxVisibleBeats = 48;

  @override
  State<EditorTimelineWorkspace> createState() =>
      _EditorTimelineWorkspaceState();
}

class _EditorTimelineWorkspaceState extends State<EditorTimelineWorkspace> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            widget.onAddManualImagePoint,
        const SingleActivator(LogicalKeyboardKey.delete):
            widget.onDeleteSelectedMarker,
        const SingleActivator(LogicalKeyboardKey.backspace):
            widget.onDeleteSelectedMarker,
      },
      child: Focus(
        autofocus: true,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimelineHeader(
                  beatMap: widget.beatMap,
                  project: widget.project,
                  playback: widget.playback,
                  selectedMedia: widget.selectedMedia,
                ),
                const SizedBox(height: 24),
                if (widget.beatMap == null && widget.project == null)
                  const _EditorEmptyState()
                else
                  _buildCanvas(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(BuildContext context) {
    final allMarkers = _timelineMarkers();
    final visibleBeats = allMarkers
        .take(
          _minInt(allMarkers.length, EditorTimelineWorkspace._maxVisibleBeats),
        )
        .toList(growable: false);
    final timelineDuration = _resolveTimelineDuration(visibleBeats);
    final clips = _buildClips(
      visibleBeats: visibleBeats,
      timelineDuration: timelineDuration,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasHeight =
            EditorTimelineWorkspace._timelineScaleHeight +
            EditorTimelineWorkspace._clipLaneHeight +
            EditorTimelineWorkspace._audioLaneHeight +
            EditorTimelineWorkspace._timelineGap;
        final availableCanvasWidth = _maxDouble(
          constraints.maxWidth - EditorTimelineWorkspace._laneLabelWidth - 24,
          0,
        );
        final timelineWidth = _maxDouble(
          availableCanvasWidth,
          visibleBeats.length * EditorTimelineWorkspace._beatWidth,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LaneLabels(
                width: EditorTimelineWorkspace._laneLabelWidth,
                timelineScaleHeight:
                    EditorTimelineWorkspace._timelineScaleHeight,
                clipLaneHeight: EditorTimelineWorkspace._clipLaneHeight,
                audioLaneHeight: EditorTimelineWorkspace._audioLaneHeight,
                timelineGap: EditorTimelineWorkspace._timelineGap,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Scrollbar(
                      key: const Key('editor-timeline-scrollbar'),
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: timelineWidth,
                          height: canvasHeight + 50,
                          child: GestureDetector(
                            key: const Key('editor-timeline-seek-area'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final targetTime = _timeForPosition(
                                position: details.localPosition.dx,
                                timelineDuration: timelineDuration,
                                timelineWidth: timelineWidth,
                              );
                              widget.onMarkerSelectionCleared();
                              widget.onCurrentPointChanged(targetTime);
                            },
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TimelineScaleRow(
                                      beats: visibleBeats,
                                      timelineWidth: timelineWidth,
                                      timelineDuration: timelineDuration,
                                    ),
                                    const SizedBox(height: 12),
                                    _ClipLane(
                                      clips: clips,
                                      timelineDuration: timelineDuration,
                                      timelineWidth: timelineWidth,
                                      height: EditorTimelineWorkspace
                                          ._clipLaneHeight,
                                      onClipSelected: widget.onMarkerSelected,
                                    ),
                                    const SizedBox(
                                      height:
                                          EditorTimelineWorkspace._timelineGap,
                                    ),
                                    _AudioLane(
                                      beats: visibleBeats,
                                      timelineDuration: timelineDuration,
                                      timelineWidth: timelineWidth,
                                      height: EditorTimelineWorkspace
                                          ._audioLaneHeight,
                                    ),
                                  ],
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: _BeatLinesOverlay(
                                      beats: visibleBeats,
                                      timelineDuration: timelineDuration,
                                      timelineWidth: timelineWidth,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: _PlayheadOverlay(
                                      currentTime:
                                          widget.playback?.currentTime ??
                                          Duration.zero,
                                      timelineDuration: timelineDuration,
                                      timelineWidth: timelineWidth,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tap the timeline to place the current point.',
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Duration _resolveTimelineDuration(List<Beat> beats) {
    final mediaEnd = _projectMediaEnd();
    final importedDuration = widget.audioDuration ?? Duration.zero;

    if (beats.isEmpty) {
      final manualDuration = _maxDuration(mediaEnd, importedDuration);
      return manualDuration > Duration.zero
          ? manualDuration
          : const Duration(seconds: 30);
    }

    final averageBeatInterval =
        widget.beatMap!.averageBeatInterval > Duration.zero
        ? widget.beatMap!.averageBeatInterval
        : const Duration(milliseconds: 500);
    return _maxDuration(beats.last.time + averageBeatInterval, mediaEnd);
  }

  List<Beat> _timelineMarkers() {
    final projectMarkers = _markerEventsFromProject();
    if (projectMarkers.isNotEmpty) {
      return [
        for (final event in projectMarkers) Beat(time: event.time, strength: 1),
      ];
    }
    return widget.beatMap?.beats ?? const [];
  }

  List<BeatEvent> _markerEventsFromProject() {
    final project = widget.project;
    if (project == null) {
      return const [];
    }
    for (final track in project.tracks) {
      if (track.id == 'track-markers') {
        return track.events;
      }
    }
    return const [];
  }

  List<_TimelineClip> _buildClips({
    required List<Beat> visibleBeats,
    required Duration timelineDuration,
  }) {
    final clipsFromProject = _buildProjectClips(
      visibleBeats: visibleBeats,
      timelineDuration: timelineDuration,
    );
    if (clipsFromProject.isNotEmpty) {
      return clipsFromProject;
    }

    return const [];
  }

  List<_TimelineClip> _buildProjectClips({
    required List<Beat> visibleBeats,
    required Duration timelineDuration,
  }) {
    final project = widget.project;
    final beatMap = widget.beatMap ?? project?.beatMap;
    if (project == null || beatMap == null) {
      return const [];
    }
    final clips = const ResolveMediaTrackClipsUseCase().call(
      beatMap: beatMap,
      project: project,
    );
    if (clips.isEmpty) {
      return const [];
    }

    return [
      for (var index = 0; index < clips.length; index++)
        if (clips[index].start <= timelineDuration)
          _TimelineClip(
            label: clips[index].title,
            subtitle: _timelineClipSubtitle(clips[index]),
            start: clips[index].start,
            end: _coerceClipEnd(
              start: clips[index].start,
              proposedEnd: clips[index].end,
              timelineDuration: timelineDuration,
              fallbackSpan: _fallbackClipSpan(visibleBeats),
            ),
            isSuggested: false,
            icon: Icons.image_outlined,
            mediaId: clips[index].mediaId,
            isSelected:
                widget.selectedMarker?.matches(
                  time: clips[index].start,
                  mediaId: clips[index].mediaId,
                ) ??
                false,
          ),
    ];
  }

  Duration _fallbackClipSpan(List<Beat> visibleBeats) {
    final averageBeatInterval =
        (widget.beatMap ?? widget.project?.beatMap)?.averageBeatInterval;
    final resolvedInterval =
        averageBeatInterval != null && averageBeatInterval > Duration.zero
        ? averageBeatInterval
        : const Duration(seconds: 2);
    final beatMultiplier = visibleBeats.length >= 16 ? 4 : 2;
    return Duration(
      microseconds: resolvedInterval.inMicroseconds * beatMultiplier,
    );
  }

  Duration _projectMediaEnd() {
    final project = widget.project;
    final beatMap = widget.beatMap ?? project?.beatMap;
    if (project == null || beatMap == null) {
      return Duration.zero;
    }

    final clips = const ResolveMediaTrackClipsUseCase().call(
      beatMap: beatMap,
      project: project,
    );
    var end = Duration.zero;
    for (final clip in clips) {
      if (clip.end > end) {
        end = clip.end;
      }
    }
    return end;
  }

  Duration _coerceClipEnd({
    required Duration start,
    required Duration proposedEnd,
    required Duration timelineDuration,
    required Duration fallbackSpan,
  }) {
    final minimumEnd = start + fallbackSpan;
    final resolvedEnd = proposedEnd > start ? proposedEnd : minimumEnd;
    if (resolvedEnd > timelineDuration) {
      return timelineDuration;
    }
    if (resolvedEnd <= start) {
      return minimumEnd <= timelineDuration ? minimumEnd : timelineDuration;
    }
    return resolvedEnd;
  }

  String _timelineClipSubtitle(MediaTrackClipPayload clip) {
    if (clip.tagline.isEmpty) {
      return 'Imported image';
    }
    return clip.tagline;
  }

  Duration _timeForPosition({
    required double position,
    required Duration timelineDuration,
    required double timelineWidth,
  }) {
    if (timelineWidth <= 0) {
      return Duration.zero;
    }

    final clampedPosition = position.clamp(0, timelineWidth) as double;
    final ratio = clampedPosition / timelineWidth;
    return Duration(
      microseconds: (timelineDuration.inMicroseconds * ratio).round(),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
    required this.beatMap,
    required this.project,
    required this.playback,
    required this.selectedMedia,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final PlaybackState? playback;
  final List<LibraryMediaItem> selectedMedia;

  @override
  Widget build(BuildContext context) {
    final markerCount = _markerCount(project) ?? beatMap?.beats.length ?? 0;
    final visibleMarkerCount = _minInt(
      markerCount,
      EditorTimelineWorkspace._maxVisibleBeats,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Timeline workspace', style: context.textTheme.titleLarge),
        Chip(
          label: Text(
            beatMap == null
                ? 'No sync'
                : beatMap!.beats.isEmpty
                ? 'Manual mode'
                : '${beatMap!.bpm.toStringAsFixed(1)} BPM',
          ),
        ),
        Chip(
          label: Text(
            beatMap == null
                ? 'No markers visible'
                : '$visibleMarkerCount / $markerCount markers visible',
          ),
        ),
        Chip(
          label: Text(
            project == null
                ? 'No image track'
                : '${project!.tracks.length} tracks loaded',
          ),
        ),
        Chip(
          label: Text(
            selectedMedia.isEmpty
                ? 'No images queued'
                : '${selectedMedia.length} images queued',
          ),
        ),
        Chip(label: Text('Next marker ${playback?.nextBeatIndex ?? 0}')),
      ],
    );
  }

  int? _markerCount(ProjectTimeline? project) {
    if (project == null) {
      return null;
    }
    for (final track in project.tracks) {
      if (track.id == 'track-markers') {
        return track.events.length;
      }
    }
    return 0;
  }
}

class _LaneLabels extends StatelessWidget {
  const _LaneLabels({
    required this.width,
    required this.timelineScaleHeight,
    required this.clipLaneHeight,
    required this.audioLaneHeight,
    required this.timelineGap,
  });

  final double width;
  final double timelineScaleHeight;
  final double clipLaneHeight;
  final double audioLaneHeight;
  final double timelineGap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: timelineScaleHeight + 12),
          _LaneLabel(
            title: 'Images',
            subtitle: 'Clips',
            height: clipLaneHeight,
            icon: Icons.photo_library_outlined,
          ),
          SizedBox(height: timelineGap),
          _LaneLabel(
            title: 'Audio',
            subtitle: 'Markers',
            height: audioLaneHeight,
            icon: Icons.graphic_eq_outlined,
          ),
        ],
      ),
    );
  }
}

class _LaneLabel extends StatelessWidget {
  const _LaneLabel({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Icon(icon, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.titleSmall),
                Text(subtitle, style: context.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineScaleRow extends StatelessWidget {
  const _TimelineScaleRow({
    required this.beats,
    required this.timelineWidth,
    required this.timelineDuration,
  });

  final List<Beat> beats;
  final double timelineWidth;
  final Duration timelineDuration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EditorTimelineWorkspace._timelineScaleHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Divider(
              color: context.colors.outlineVariant,
              height: EditorTimelineWorkspace._timelineScaleHeight,
            ),
          ),
          for (var index = 0; index < beats.length; index++)
            if (index == 0 || _isMajorBeat(index))
              Positioned(
                left: _positionForTime(
                  beats[index].time,
                  timelineDuration,
                  timelineWidth,
                ),
                child: Text(
                  _formatDuration(beats[index].time),
                  style: context.textTheme.labelSmall,
                ),
              ),
        ],
      ),
    );
  }
}

class _ClipLane extends StatelessWidget {
  const _ClipLane({
    required this.clips,
    required this.timelineDuration,
    required this.timelineWidth,
    required this.height,
    required this.onClipSelected,
  });

  final List<_TimelineClip> clips;
  final Duration timelineDuration;
  final double timelineWidth;
  final double height;
  final ValueChanged<TimelineMarkerSelection> onClipSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + 24,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Stack(
        children: [
          for (final clip in clips)
            Positioned(
              left: _positionForTime(
                clip.start,
                timelineDuration,
                timelineWidth,
              ),
              child: _ClipBlock(
                clip: clip,
                width: _widthForSpan(
                  start: clip.start,
                  end: clip.end,
                  timelineDuration: timelineDuration,
                  timelineWidth: timelineWidth,
                ),
                height: height,
                onSelected: onClipSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _ClipBlock extends StatelessWidget {
  const _ClipBlock({
    required this.clip,
    required this.width,
    required this.height,
    required this.onSelected,
  });

  final _TimelineClip clip;
  final double width;
  final double height;
  final ValueChanged<TimelineMarkerSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final clipColor = clip.isSuggested
        ? context.colors.secondaryContainer
        : context.colors.primaryContainer;
    final onClipColor = clip.isSuggested
        ? context.colors.onSecondaryContainer
        : context.colors.onPrimaryContainer;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(
        TimelineMarkerSelection(time: clip.start, mediaId: clip.mediaId),
      ),
      child: Container(
        width: _maxDouble(width, 72),
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: clipColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: clip.isSelected
                ? context.colors.primary
                : context.colors.outlineVariant,
            width: clip.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(clip.icon, color: onClipColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    clip.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clip.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioLane extends StatelessWidget {
  const _AudioLane({
    required this.beats,
    required this.timelineDuration,
    required this.timelineWidth,
    required this.height,
  });

  final List<Beat> beats;
  final Duration timelineDuration;
  final double timelineWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: beats
                    .map(
                      (beat) => Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 6,
                            height:
                                16 +
                                beat.strength.clamp(0.0, 1.0).toDouble() * 32,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          for (var index = 0; index < beats.length; index++)
            if (index == 0 || _isMajorBeat(index))
              Positioned(
                left: _positionForTime(
                  beats[index].time,
                  timelineDuration,
                  timelineWidth,
                ),
                bottom: 8,
                child: Text(
                  'B${index + 1}',
                  style: context.textTheme.labelSmall,
                ),
              ),
        ],
      ),
    );
  }
}

class _BeatLinesOverlay extends StatelessWidget {
  const _BeatLinesOverlay({
    required this.beats,
    required this.timelineDuration,
    required this.timelineWidth,
  });

  final List<Beat> beats;
  final Duration timelineDuration;
  final double timelineWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var index = 0; index < beats.length; index++)
          Positioned(
            left: _positionForTime(
              beats[index].time,
              timelineDuration,
              timelineWidth,
            ),
            top: 0,
            bottom: 0,
            child: Container(
              width: _isMajorBeat(index) ? 2 : 1,
              color: _isMajorBeat(index)
                  ? context.colors.outline
                  : context.colors.outlineVariant,
            ),
          ),
      ],
    );
  }
}

class _PlayheadOverlay extends StatelessWidget {
  const _PlayheadOverlay({
    required this.currentTime,
    required this.timelineDuration,
    required this.timelineWidth,
  });

  final Duration currentTime;
  final Duration timelineDuration;
  final double timelineWidth;

  @override
  Widget build(BuildContext context) {
    final playheadLeft = _positionForTime(
      currentTime,
      timelineDuration,
      timelineWidth,
    );

    return Stack(
      children: [
        Positioned(
          left: playheadLeft,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: context.colors.primary),
        ),
        Positioned(
          left: _maxDouble(playheadLeft - 24, 0),
          top: 0,
          child: Chip(
            avatar: Icon(
              Icons.play_arrow,
              size: 16,
              color: context.colors.onPrimaryContainer,
            ),
            label: Text(_formatDuration(currentTime)),
          ),
        ),
      ],
    );
  }
}

class _EditorEmptyState extends StatelessWidget {
  const _EditorEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 36,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Editor waiting for beat-aware data',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Return to the import flow, run beat detection, build the beat map, then come back here for preview and timeline editing.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToImportAudio(),
                  icon: const Icon(Icons.audio_file_outlined),
                  label: const Text('Go to import'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToLibrary(),
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Browse library'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineClip {
  const _TimelineClip({
    required this.label,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.isSuggested,
    required this.icon,
    required this.mediaId,
    required this.isSelected,
  });

  final String label;
  final String subtitle;
  final Duration start;
  final Duration end;
  final bool isSuggested;
  final IconData icon;
  final String mediaId;
  final bool isSelected;
}

double _positionForTime(
  Duration time,
  Duration timelineDuration,
  double timelineWidth,
) {
  if (timelineDuration <= Duration.zero) {
    return 0;
  }

  final clampedMicros = _minInt(
    time.inMicroseconds,
    timelineDuration.inMicroseconds,
  );
  return timelineWidth * (clampedMicros / timelineDuration.inMicroseconds);
}

double _widthForSpan({
  required Duration start,
  required Duration end,
  required Duration timelineDuration,
  required double timelineWidth,
}) {
  final startX = _positionForTime(start, timelineDuration, timelineWidth);
  final endX = _positionForTime(end, timelineDuration, timelineWidth);
  return _maxDouble(endX - startX, 56);
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

int _minInt(int a, int b) => a < b ? a : b;

double _maxDouble(num a, num b) {
  return (a > b ? a : b).toDouble();
}

Duration _maxDuration(Duration a, Duration b) => a > b ? a : b;

bool _isMajorBeat(int index) => index % 4 == 0;
