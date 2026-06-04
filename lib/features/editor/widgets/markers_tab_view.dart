import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class MarkersTabView extends StatelessWidget {
  const MarkersTabView({
    required this.beatMap,
    required this.project,
    required this.events,
    required this.selectedMarker,
    required this.onAddMarker,
    required this.onDeleteMarker,
    required this.onMarkerSelected,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final List<BeatEvent> events;
  final TimelineMarkerSelection? selectedMarker;
  final VoidCallback onAddMarker;
  final VoidCallback onDeleteMarker;
  final ValueChanged<Duration> onMarkerSelected;

  @override
  Widget build(BuildContext context) {
    final markers = _markers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${markers.length} beat markers',
                style: context.textTheme.titleMedium,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: beatMap == null ? null : onAddMarker,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add marker'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < markers.length; index++) ...[
          _MarkerListItem(
            marker: markers[index],
            index: index,
            selected: selectedMarker?.time == markers[index].time,
            onSelected: () => onMarkerSelected(markers[index].time),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: selectedMarker == null ? null : onDeleteMarker,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete marker'),
        ),
      ],
    );
  }

  List<BeatEvent> get _markers {
    final tracks = project?.tracks ?? const [];
    for (final track in tracks) {
      if (track.id == 'track-markers' && track.events.isNotEmpty) {
        return track.events;
      }
    }
    if (events.isNotEmpty) {
      return events;
    }
    if (beatMap?.beats.isNotEmpty ?? false) {
      return [
        for (var index = 0; index < beatMap!.beats.length; index++)
          BeatEvent(
            time: beatMap!.beats[index].time,
            type: 'marker',
            payload: 'B${index + 1}',
          ),
      ];
    }
    return const [
      BeatEvent(time: Duration(seconds: 1), type: 'marker', payload: 'B1'),
      BeatEvent(time: Duration(seconds: 4), type: 'marker', payload: 'B2'),
      BeatEvent(time: Duration(seconds: 7), type: 'marker', payload: 'B3'),
      BeatEvent(time: Duration(seconds: 11), type: 'marker', payload: 'B4'),
    ];
  }
}

class _MarkerListItem extends StatelessWidget {
  const _MarkerListItem({
    required this.marker,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final BeatEvent marker;
  final int index;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        selected: selected,
        leading: CircleAvatar(child: Text(_markerName)),
        title: Text('Marker ${index + 1}'),
        subtitle: Text(_formatDuration(marker.time)),
        trailing: IconButton(
          onPressed: null,
          icon: const Icon(Icons.edit_outlined),
        ),
        onTap: onSelected,
      ),
    );
  }

  String get _markerName {
    final payload = marker.payload;
    if (payload is String && payload.length <= 3) {
      return payload;
    }
    return 'B${index + 1}';
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
