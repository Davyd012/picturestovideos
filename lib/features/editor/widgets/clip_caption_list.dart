import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/editor/editor_clip_selection_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

enum ClipCaptionSort {
  timeline,
  nameAscending,
  nameDescending,
  modifiedOldest,
  modifiedNewest,
}

@immutable
class ClipCaptionListEntry {
  const ClipCaptionListEntry({
    required this.clip,
    required this.timelineIndex,
    this.modifiedAt,
  });

  final MediaTrackClipPayload clip;
  final int timelineIndex;
  final DateTime? modifiedAt;
}

List<ClipCaptionListEntry> sortClipCaptionEntries(
  List<ClipCaptionListEntry> entries,
  ClipCaptionSort sort,
) {
  final result = [...entries];
  result.sort((first, second) {
    final comparison = switch (sort) {
      ClipCaptionSort.timeline => 0,
      ClipCaptionSort.nameAscending => first.clip.title.toLowerCase().compareTo(
        second.clip.title.toLowerCase(),
      ),
      ClipCaptionSort.nameDescending =>
        second.clip.title.toLowerCase().compareTo(
          first.clip.title.toLowerCase(),
        ),
      ClipCaptionSort.modifiedOldest || ClipCaptionSort.modifiedNewest =>
        _compareDates(first.modifiedAt, second.modifiedAt, sort),
    };
    return comparison == 0
        ? first.timelineIndex.compareTo(second.timelineIndex)
        : comparison;
  });
  return List.unmodifiable(result);
}

int _compareDates(DateTime? first, DateTime? second, ClipCaptionSort sort) {
  if (first == null || second == null) {
    if (first == null && second == null) return 0;
    return first == null ? 1 : -1;
  }
  final order = first.compareTo(second);
  return sort == ClipCaptionSort.modifiedNewest ? -order : order;
}

class ClipCaptionList extends ConsumerStatefulWidget {
  const ClipCaptionList({
    required this.clips,
    required this.onEdit,
    this.onSelect,
    this.onRemove,
    this.onMove,
    this.onReorder,
    super.key,
  });

  final List<MediaTrackClipPayload> clips;
  final void Function(MediaTrackClipPayload clip, MediaTrackClipPayload? next)
  onEdit;
  final ValueChanged<MediaTrackClipPayload>? onSelect;
  final ValueChanged<String>? onRemove;
  final bool Function(String clipId, int position)? onMove;
  final bool Function(String clipId, int position)? onReorder;

  @override
  ConsumerState<ClipCaptionList> createState() => _ClipCaptionListState();
}

class _ClipCaptionListState extends ConsumerState<ClipCaptionList> {
  late Future<Map<String, DateTime?>> _modifiedDates;

  @override
  void initState() {
    super.initState();
    _modifiedDates = _loadModifiedDates(widget.clips);
  }

  @override
  void didUpdateWidget(covariant ClipCaptionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameClipSources(oldWidget.clips, widget.clips)) {
      _modifiedDates = _loadModifiedDates(widget.clips);
    }
    final selected = ref
        .read(editorClipSelectionViewModelProvider)
        .selectedClipId;
    if (selected != null &&
        !widget.clips.any((clip) => clip.clipId == selected)) {
      ref
          .read(editorClipSelectionViewModelProvider.notifier)
          .clipSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, DateTime?>>(
    future: _modifiedDates,
    builder: (context, snapshot) {
      final dates = snapshot.data ?? const <String, DateTime?>{};
      final workspaceState = ref.watch(editorClipSelectionViewModelProvider);
      final sort =
          ClipCaptionSort.values[workspaceState.sortIndex.clamp(
            0,
            ClipCaptionSort.values.length - 1,
          )];
      final entries = [
        for (var index = 0; index < widget.clips.length; index++)
          ClipCaptionListEntry(
            clip: widget.clips[index],
            timelineIndex: index,
            modifiedAt: dates[widget.clips[index].clipId],
          ),
      ];
      final sorted = sortClipCaptionEntries(entries, sort);
      final repeatedCounts = <String, int>{};
      for (final clip in widget.clips) {
        repeatedCounts.update(
          clip.mediaId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      final hasModifiedDate = dates.values.any((date) => date != null);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.clipCaptions,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  Semantics(
                    label: context.l10n.clipCaptions,
                    value: widget.clips.length.toString(),
                    child: Text(widget.clips.length.toString()),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.clips.length > 1 && widget.onReorder != null)
                    TextButton.icon(
                      onPressed: () => ref
                          .read(editorClipSelectionViewModelProvider.notifier)
                          .reorderModeToggled(),
                      icon: Icon(
                        workspaceState.reorderMode
                            ? Icons.check
                            : Icons.drag_handle,
                      ),
                      label: Text(
                        workspaceState.reorderMode
                            ? context.l10n.done
                            : context.l10n.reorder,
                      ),
                    ),
                  PopupMenuButton<ClipCaptionSort>(
                    tooltip: context.l10n.clipListSort,
                    initialValue: sort,
                    onSelected: (value) => ref
                        .read(editorClipSelectionViewModelProvider.notifier)
                        .sortSelected(value.index),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ClipCaptionSort.timeline,
                        child: Text(context.l10n.clipSortTimeline),
                      ),
                      PopupMenuItem(
                        value: ClipCaptionSort.nameAscending,
                        child: Text(context.l10n.clipSortNameAscending),
                      ),
                      PopupMenuItem(
                        value: ClipCaptionSort.nameDescending,
                        child: Text(context.l10n.clipSortNameDescending),
                      ),
                      PopupMenuItem(
                        value: ClipCaptionSort.modifiedOldest,
                        enabled: hasModifiedDate,
                        child: Text(context.l10n.clipSortModifiedOldest),
                      ),
                      PopupMenuItem(
                        value: ClipCaptionSort.modifiedNewest,
                        enabled: hasModifiedDate,
                        child: Text(context.l10n.clipSortModifiedNewest),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_sortLabel(context, sort))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (sort != ClipCaptionSort.timeline)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => ref
                    .read(editorClipSelectionViewModelProvider.notifier)
                    .sortSelected(ClipCaptionSort.timeline.index),
                child: Text(context.l10n.returnToTimelineOrder),
              ),
            ),
          Expanded(
            child: widget.clips.isEmpty
                ? Center(child: Text(context.l10n.noTimelineClips))
                : workspaceState.reorderMode && sort == ClipCaptionSort.timeline
                ? ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: sorted.length,
                    onReorderItem: (oldIndex, newIndex) {
                      if (oldIndex != newIndex) {
                        final didMove =
                            widget.onReorder?.call(
                              sorted[oldIndex].clip.clipId,
                              newIndex + 1,
                            ) ??
                            false;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                didMove
                                    ? context.l10n.clipMovedToPosition(
                                        newIndex + 1,
                                      )
                                    : context.l10n.moveFailed,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context, index) {
                      final entry = sorted[index];
                      return _row(
                        context,
                        entry,
                        dates,
                        repeatedCounts,
                        entries,
                        index,
                        true,
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final entry = sorted[index];
                      return _row(
                        context,
                        entry,
                        dates,
                        repeatedCounts,
                        entries,
                        index,
                        false,
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );

  Widget _row(
    BuildContext context,
    ClipCaptionListEntry entry,
    Map<String, DateTime?> dates,
    Map<String, int> repeatedCounts,
    List<ClipCaptionListEntry> entries,
    int index,
    bool reorderMode,
  ) {
    final workspaceState = ref.watch(editorClipSelectionViewModelProvider);
    final sort =
        ClipCaptionSort.values[workspaceState.sortIndex.clamp(
          0,
          ClipCaptionSort.values.length - 1,
        )];
    final nextIndex = entry.timelineIndex + 1;
    return _ClipCaptionRow(
      key: reorderMode ? ValueKey(entry.clip.clipId) : null,
      entry: entry,
      selected: entry.clip.clipId == workspaceState.selectedClipId,
      modifiedDate: dates[entry.clip.clipId],
      isDateSort:
          sort == ClipCaptionSort.modifiedOldest ||
          sort == ClipCaptionSort.modifiedNewest,
      repeatedCount: repeatedCounts[entry.clip.mediaId] ?? 1,
      repeatedOccurrences: entries
          .where((other) => other.clip.mediaId == entry.clip.mediaId)
          .toList(growable: false),
      reorderMode: reorderMode,
      dragIndex: index,
      onSelected: () {
        ref
            .read(editorClipSelectionViewModelProvider.notifier)
            .clipSelected(entry.clip.clipId);
        widget.onSelect?.call(entry.clip);
      },
      onEdit: () {
        ref
            .read(editorClipSelectionViewModelProvider.notifier)
            .clipSelected(entry.clip.clipId);
        widget.onSelect?.call(entry.clip);
        widget.onEdit(
          entry.clip,
          nextIndex < widget.clips.length ? widget.clips[nextIndex] : null,
        );
      },
      onMove:
          !reorderMode ||
              widget.onMove == null ||
              sort != ClipCaptionSort.timeline
          ? null
          : () => _move(context, entry),
      onRemove: widget.onRemove == null
          ? null
          : () => widget.onRemove!(entry.clip.clipId),
    );
  }

  Future<void> _move(BuildContext context, ClipCaptionListEntry entry) async {
    final formKey = GlobalKey<FormState>();
    var input = '${entry.timelineIndex + 1}';
    final position = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.moveImage),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.position,
              helperText: context.l10n.positionRange(widget.clips.length),
            ),
            onChanged: (value) => input = value,
            validator: (value) {
              final number = int.tryParse(value ?? '');
              return number == null ||
                      number < 1 ||
                      number > widget.clips.length
                  ? context.l10n.positionRange(widget.clips.length)
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, int.parse(input));
              }
            },
            child: Text(context.l10n.move),
          ),
        ],
      ),
    );
    if (position != null) {
      final didMove = widget.onMove?.call(entry.clip.clipId, position) ?? false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              didMove
                  ? context.l10n.clipMovedToPosition(position)
                  : context.l10n.moveFailed,
            ),
          ),
        );
      }
    }
  }

  String _sortLabel(BuildContext context, ClipCaptionSort sort) =>
      switch (sort) {
        ClipCaptionSort.timeline => context.l10n.clipSortTimeline,
        ClipCaptionSort.nameAscending => context.l10n.clipSortNameAscending,
        ClipCaptionSort.nameDescending => context.l10n.clipSortNameDescending,
        ClipCaptionSort.modifiedOldest => context.l10n.clipSortModifiedOldest,
        ClipCaptionSort.modifiedNewest => context.l10n.clipSortModifiedNewest,
      };

  Future<Map<String, DateTime?>> _loadModifiedDates(
    List<MediaTrackClipPayload> clips,
  ) async {
    final sourceDates = <String, DateTime?>{};
    await Future.wait(
      clips
          .map((clip) => clip.sourcePath)
          .where((path) => path.isNotEmpty)
          .toSet()
          .map((path) async {
            try {
              final stat = await File(path).stat();
              sourceDates[path] = stat.type == FileSystemEntityType.notFound
                  ? null
                  : stat.modified;
            } on FileSystemException {
              sourceDates[path] = null;
            }
          }),
    );
    return {
      for (final clip in clips) clip.clipId: sourceDates[clip.sourcePath],
    };
  }

  bool _sameClipSources(
    List<MediaTrackClipPayload> first,
    List<MediaTrackClipPayload> second,
  ) =>
      first.length == second.length &&
      first.every(
        (clip) => second.any(
          (other) =>
              other.clipId == clip.clipId &&
              other.sourcePath == clip.sourcePath,
        ),
      );
}

class _ClipCaptionRow extends StatelessWidget {
  const _ClipCaptionRow({
    super.key,
    required this.entry,
    required this.selected,
    required this.modifiedDate,
    required this.isDateSort,
    required this.repeatedCount,
    required this.repeatedOccurrences,
    required this.onSelected,
    required this.onEdit,
    required this.reorderMode,
    this.dragIndex,
    this.onMove,
    this.onRemove,
  });

  final ClipCaptionListEntry entry;
  final bool selected;
  final DateTime? modifiedDate;
  final int repeatedCount;
  final bool isDateSort;
  final List<ClipCaptionListEntry> repeatedOccurrences;
  final VoidCallback onSelected;
  final VoidCallback onEdit;
  final bool reorderMode;
  final int? dragIndex;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final clip = entry.clip;
    final caption = [
      clip.caption,
      clip.captionSupportingLine,
    ].where((line) => line.trim().isNotEmpty).join(' · ');
    return Semantics(
      selected: selected,
      child: Card.outlined(
        color: selected ? context.colors.surfaceContainerHighest : null,
        child: ListTile(
          leading: _ClipThumbnail(sourcePath: clip.sourcePath),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.clipNumber(entry.timelineIndex + 1, clip.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) ...[
                Icon(
                  Icons.check_circle_outline,
                  color: context.colors.onSurface,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.selected),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatDuration(clip.start)}–${_formatDuration(clip.end)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                caption.isEmpty ? context.l10n.noCaption : caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isDateSort)
                Text(
                  modifiedDate == null
                      ? context.l10n.clipDateUnavailable
                      : _formatDate(modifiedDate!),
                  style: context.textTheme.labelSmall,
                ),
              if (repeatedCount > 1)
                ActionChip(
                  avatar: const Icon(Icons.repeat, size: 18),
                  label: Text(context.l10n.clipRepeatedSource),
                  onPressed: () => _showOccurrences(context),
                ),
            ],
          ),
          trailing: reorderMode
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.l10n.moveToPosition,
                      onPressed: onMove,
                      icon: const Icon(Icons.format_list_numbered),
                    ),
                    ReorderableDragStartListener(
                      index: dragIndex!,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.l10n.editClip,
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    if (onRemove != null)
                      PopupMenuButton<String>(
                        tooltip: context.l10n.clipActions,
                        onSelected: (action) {
                          if (action == 'remove') onRemove?.call();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(context.l10n.removeClip),
                          ),
                        ],
                      ),
                  ],
                ),
          onTap: onSelected,
          isThreeLine: true,
        ),
      ),
    );
  }

  Future<void> _showOccurrences(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.clipRepeatedDetails),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final occurrence in repeatedOccurrences)
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(context.l10n.clipOccurrence),
              subtitle: Text(
                '${context.l10n.clipNumber(occurrence.timelineIndex + 1, occurrence.clip.title)} · ${_formatDuration(occurrence.clip.start)}–${_formatDuration(occurrence.clip.end)}\n${occurrence.clip.caption.isEmpty ? context.l10n.noCaption : occurrence.clip.caption}',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
      ],
    ),
  );
}

class _ClipThumbnail extends StatelessWidget {
  const _ClipThumbnail({required this.sourcePath});

  final String sourcePath;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(8)),
    child: SizedBox.square(
      dimension: 56,
      child: sourcePath.isEmpty
          ? _fallback(context)
          : Image.file(
              File(sourcePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(context),
            ),
    ),
  );

  Widget _fallback(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHighest,
    child: Icon(Icons.image_outlined, color: context.colors.onSurfaceVariant),
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
