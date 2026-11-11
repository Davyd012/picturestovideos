import 'package:flutter/material.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/timeline_marker_payload.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/timeline/timeline_marker_selection.dart';
import 'package:picturestovideos/features/timeline/marker_assignment_targets.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class MarkersTabView extends StatelessWidget {
  const MarkersTabView({
    this.beatMap,
    required this.project,
    this.selectedMedia = const [],
    this.events = const [],
    required this.selectedMarker,
    required this.onAddMarker,
    required this.onDeleteMarker,
    required this.onDeleteMarkerAtCurrentPoint,
    required this.onClearMarkers,
    required this.canSaveMarkerPreset,
    required this.onSaveMarkerPreset,
    required this.onMarkerSelected,
    this.onMarkerDeletedAt,
    this.onMarkerTimeChanged,
    this.onApplyMarkers,
    this.onUndoAvailable,
    super.key,
  });

  final BeatMap? beatMap;
  final ProjectTimeline? project;
  final List<LibraryMediaItem> selectedMedia;
  final List<BeatEvent> events;
  final TimelineMarkerSelection? selectedMarker;
  final VoidCallback onAddMarker;
  final VoidCallback onDeleteMarker;
  final VoidCallback onDeleteMarkerAtCurrentPoint;
  final VoidCallback onClearMarkers;
  final bool canSaveMarkerPreset;
  final VoidCallback onSaveMarkerPreset;
  final ValueChanged<Duration> onMarkerSelected;
  final ValueChanged<Duration>? onMarkerDeletedAt;
  final ValueChanged<Duration>? onMarkerTimeChanged;
  final VoidCallback? onApplyMarkers;
  final VoidCallback? onUndoAvailable;

  @override
  Widget build(BuildContext context) {
    final markers = _markers;
    final targets = markerAssignmentTargets(project, selectedMedia);
    final selected = markers.where(_isSelected).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.l10n.markerCount(markers.length),
              style: context.textTheme.titleMedium,
            ),
            FilledButton.icon(
              onPressed: onAddMarker,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addMarker),
            ),
            if (markers.isNotEmpty)
              PopupMenuButton<_MarkerMenuAction>(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                onSelected: (action) {
                  switch (action) {
                    case _MarkerMenuAction.savePreset:
                      onSaveMarkerPreset();
                      break;
                    case _MarkerMenuAction.clear:
                      _confirmClear(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (canSaveMarkerPreset)
                    PopupMenuItem(
                      value: _MarkerMenuAction.savePreset,
                      child: Text(context.l10n.saveMarkerPreset),
                    ),
                  PopupMenuItem(
                    value: _MarkerMenuAction.clear,
                    child: Text(context.l10n.clearMarkers),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: selected == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SelectedMarkerPanel(
                      marker: selected,
                      index: markers.indexOf(selected),
                      onDelete: () {
                        onDeleteMarker();
                        onUndoAvailable?.call();
                      },
                      onTimeChanged: onMarkerTimeChanged,
                      onGoTo: () => onMarkerSelected(selected.time),
                      onUndoAvailable: onUndoAvailable,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        if (markers.isNotEmpty && targets.isNotEmpty && onApplyMarkers != null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showApplyPreview(context, markers, targets),
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(context.l10n.applyMarkersToImages),
            ),
          ),
        if (markers.isEmpty)
          const _EmptyMarkers()
        else ...[
          for (var index = 0; index < markers.length; index++) ...[
            _MarkerListItem(
              marker: markers[index],
              index: index,
              project: project,
              selected: _isSelected(markers[index]),
              onSelected: () => onMarkerSelected(markers[index].time),
              onDelete: () {
                final deleteAt = onMarkerDeletedAt;
                if (deleteAt != null) {
                  deleteAt(markers[index].time);
                } else {
                  onMarkerSelected(markers[index].time);
                  onDeleteMarker();
                }
                onUndoAvailable?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (markers.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                onDeleteMarkerAtCurrentPoint();
                onUndoAvailable?.call();
              },
              icon: const Icon(Icons.remove_circle_outline),
              label: Text(context.l10n.deleteMarkerAtPlayhead),
            ),
          ),
      ],
    );
  }

  List<BeatEvent> get _markers {
    final markerTrack = project?.tracks
        .where((track) => track.id == 'track-markers')
        .firstOrNull;
    if (markerTrack == null) return const [];
    final markers =
        markerTrack.events.where((event) => !event.time.isNegative).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    return markers;
  }

  bool _isSelected(BeatEvent event) {
    final selection = selectedMarker;
    if (selection == null) return false;
    final payload = event.payload;
    if (selection.markerId != null && payload is TimelineMarkerPayload) {
      return payload.id == selection.markerId;
    }
    return event.time == selection.time;
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(context.l10n.clearMarkersConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.clearMarkers),
          ),
        ],
      ),
    );
    if (clear == true) {
      onClearMarkers();
      onUndoAvailable?.call();
    }
  }

  Future<void> _showApplyPreview(
    BuildContext context,
    List<BeatEvent> markers,
    List<MarkerAssignmentTarget> targets,
  ) async {
    final count = targets.length < markers.length
        ? targets.length
        : markers.length;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.markerAssignmentPreview),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.applyMarkersDescription),
                const SizedBox(height: 12),
                for (var index = 0; index < count; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Text(_formatDuration(markers[index].time)),
                    title: Text(
                      targets[index].clip?.title ?? targets[index].item!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (markers.length > count)
                  Text(
                    context.l10n.markersUnassignedCount(markers.length - count),
                  ),
                if (targets.length > count)
                  Text(
                    context.l10n.imagesUnassignedCount(targets.length - count),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.apply),
          ),
        ],
      ),
    );
    if (apply == true) {
      onApplyMarkers?.call();
      onUndoAvailable?.call();
    }
  }
}

enum _MarkerMenuAction { savePreset, clear }

class _EmptyMarkers extends StatelessWidget {
  const _EmptyMarkers();

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.bookmark_border, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.markersEmptyTitle,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.markersEmptyHint,
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

class _MarkerListItem extends StatelessWidget {
  const _MarkerListItem({
    required this.marker,
    required this.index,
    required this.project,
    required this.selected,
    required this.onSelected,
    required this.onDelete,
  });

  final BeatEvent marker;
  final int index;
  final ProjectTimeline? project;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final payload = marker.payload;
    final linkedClipId = payload is TimelineMarkerPayload
        ? payload.linkedClipId
        : null;
    final clip = _findClip(linkedClipId);
    final name = clip?.title ?? context.l10n.unassignedMarker;
    return Card.outlined(
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: context.colors.primaryContainer,
        selectedColor: context.colors.onPrimaryContainer,
        leading: CircleAvatar(
          backgroundColor: context.colors.surfaceContainerHighest,
          child: Text('${index + 1}', style: context.textTheme.labelLarge),
        ),
        title: Text(
          _formatDuration(marker.time),
          style: context.textTheme.titleSmall,
        ),
        subtitle: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: onSelected,
      ),
    );
  }

  MediaTrackClipPayload? _findClip(String? clipId) {
    if (clipId == null) return null;
    for (final track in project?.tracks ?? const []) {
      if (track.id != 'track-media') continue;
      for (final event in track.events) {
        final clip = event.payload;
        if (clip is MediaTrackClipPayload && clip.clipId == clipId) return clip;
      }
    }
    return null;
  }
}

class _SelectedMarkerPanel extends StatelessWidget {
  const _SelectedMarkerPanel({
    required this.marker,
    required this.index,
    required this.onDelete,
    this.onTimeChanged,
    required this.onGoTo,
    this.onUndoAvailable,
  });

  final BeatEvent marker;
  final int index;
  final VoidCallback onDelete;
  final ValueChanged<Duration>? onTimeChanged;
  final VoidCallback onGoTo;
  final VoidCallback? onUndoAvailable;

  @override
  Widget build(BuildContext context) {
    final linked =
        marker.payload is TimelineMarkerPayload &&
        (marker.payload as TimelineMarkerPayload).linkedClipId != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${context.l10n.marker} ${index + 1}',
                  style: context.textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onGoTo,
                  icon: const Icon(Icons.my_location),
                  label: Text(context.l10n.goToMarker),
                ),
              ],
            ),
            Text(
              _formatDuration(marker.time),
              style: context.textTheme.headlineSmall,
            ),
            if (linked) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.markerLinkedImageMoves,
                style: context.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final step in const [-1000, -100, -10, 10, 100, 1000])
                  Tooltip(
                    message: context.l10n.markerNudge(_stepLabel(step)),
                    child: OutlinedButton(
                      onPressed: onTimeChanged == null
                          ? null
                          : () {
                              onTimeChanged!(
                                Duration(
                                  milliseconds:
                                      (marker.time.inMilliseconds + step).clamp(
                                        0,
                                        24 * 60 * 60 * 1000,
                                      ),
                                ),
                              );
                              onUndoAvailable?.call();
                            },
                      child: Text(_stepLabel(step)),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onTimeChanged == null
                      ? null
                      : () => _editTime(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.l10n.editMarkerTime),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.deleteSelected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTime(BuildContext context) async {
    final controller = TextEditingController(
      text: _formatDuration(marker.time),
    );
    String? validationMessage;
    final value = await showDialog<Duration>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.editMarkerTime),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              hintText: context.l10n.markerTimeFormatHint,
              errorText: validationMessage,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final parsed = _parseDuration(controller.text);
                if (parsed == null) {
                  setDialogState(() {
                    validationMessage = context.l10n.invalidMarkerTime;
                  });
                  return;
                }
                Navigator.of(dialogContext).pop(parsed);
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null) {
      onTimeChanged?.call(value);
      onUndoAvailable?.call();
    }
  }
}

String _stepLabel(int milliseconds) {
  final amount = milliseconds.abs();
  final label = amount >= 1000 ? '${amount ~/ 1000}s' : '${amount}ms';
  return milliseconds < 0 ? '−$label' : '+$label';
}

Duration? _parseDuration(String value) {
  final normalized = value.trim();
  final hoursMatch = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})\.(\d{1,3})$')
      .firstMatch(normalized);
  if (hoursMatch != null) {
    final hours = int.parse(hoursMatch.group(1)!);
    final minutes = int.parse(hoursMatch.group(2)!);
    final seconds = int.parse(hoursMatch.group(3)!);
    final fraction = hoursMatch.group(4)!.padRight(3, '0');
    if (minutes > 59 || seconds > 59) return null;
    return Duration(
      milliseconds:
          hours * 3600000 +
          minutes * 60000 +
          seconds * 1000 +
          int.parse(fraction),
    );
  }
  final match = RegExp(r'^(\d{1,3}):(\d{2})\.(\d{1,3})$')
      .firstMatch(normalized);
  if (match == null) return null;
  final minutes = int.parse(match.group(1)!);
  final seconds = int.parse(match.group(2)!);
  final fraction = match.group(3)!.padRight(3, '0');
  if (seconds > 59) return null;
  return Duration(
    milliseconds: minutes * 60000 + seconds * 1000 + int.parse(fraction),
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final millis = duration.inMilliseconds
      .remainder(1000)
      .toString()
      .padLeft(3, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:$seconds.$millis'
      : '$minutes:$seconds.$millis';
}
