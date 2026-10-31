import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class EditorWorkspaceTab extends StatelessWidget {
  const EditorWorkspaceTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: selected
                ? context.colors.secondary
                : context.colors.surfaceContainerHighest,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('$count'),
        ],
      ),
    ),
  );
}

class EditorPlaybackBar extends StatelessWidget {
  const EditorPlaybackBar({
    super.key,
    required this.current,
    required this.duration,
    required this.canPlay,
    required this.playing,
    required this.onSeek,
    required this.onPlay,
    required this.onFullscreen,
    required this.onVolume,
  });
  final Duration current;
  final Duration duration;
  final bool canPlay;
  final bool playing;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPlay;
  final VoidCallback onFullscreen;
  final VoidCallback onVolume;
  @override
  Widget build(BuildContext context) {
    final total = math.max(1, duration.inMilliseconds);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Slider(
            value: (current.inMilliseconds / total).clamp(0.0, 1.0),
            onChanged: duration > Duration.zero
                ? (v) => onSeek(Duration(milliseconds: (v * total).round()))
                : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_time(current)} / ${_time(duration)}',
                  style: context.textTheme.labelMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: '−10s',
              onPressed: canPlay
                  ? () => onSeek(
                      Duration(
                        milliseconds: math.max(
                          0,
                          current.inMilliseconds - 10000,
                        ),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filled(
              onPressed: canPlay ? onPlay : null,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: '+10s',
              onPressed: canPlay
                  ? () => onSeek(
                      Duration(
                        milliseconds: math.min(
                          total,
                          current.inMilliseconds + 10000,
                        ),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.skip_next),
            ),
            IconButton(
              onPressed: onVolume,
              icon: const Icon(Icons.volume_up_outlined),
            ),
            IconButton(
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen),
            ),
          ],
        ),
      ],
    );
  }
}

String _time(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.enabled,
    required this.onSettings,
    required this.onMore,
  });
  final bool enabled;
  final VoidCallback onSettings;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        _button(
          context,
          Icons.content_cut,
          context.l10n.editorCrop,
          enabled ? onSettings : null,
        ),
        _button(
          context,
          Icons.text_fields,
          context.l10n.editorText,
          enabled ? onSettings : null,
        ),
        _button(
          context,
          Icons.speed,
          context.l10n.editorSpeed,
          enabled ? onSettings : null,
        ),
        _button(context, Icons.more_horiz, context.l10n.editorMore, onMore),
      ],
    ),
  );
  Widget _button(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.tonal(
        onPressed: onTap,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
