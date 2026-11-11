import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_route_args.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
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

class EditorPlaybackBar extends ConsumerWidget {
  const EditorPlaybackBar({
    super.key,
    required this.duration,
    required this.canPlay,
    required this.onSeek,
    required this.onPlay,
    required this.onFullscreen,
    required this.onVolume,
  });
  final Duration duration;
  final bool canPlay;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPlay;
  final VoidCallback onFullscreen;
  final VoidCallback onVolume;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackViewModelProvider).asData?.value;
    final current = playback?.currentTime ?? Duration.zero;
    final playing = playback?.isPlaying ?? false;
    final resolvedDuration = duration > Duration.zero
        ? duration
        : playback?.sourceDuration ?? Duration.zero;
    final total = math.max(1, resolvedDuration.inMilliseconds);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Slider(
            value: (current.inMilliseconds / total).clamp(0.0, 1.0),
            onChanged: resolvedDuration > Duration.zero
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
                  '${_time(current)} / ${_time(resolvedDuration)}',
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(playing),
                ),
              ),
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
    required this.onAudio,
    required this.onMarkers,
  });
  final bool enabled;
  final ValueChanged<ImageSettingsSection> onSettings;
  final VoidCallback onAudio;
  final VoidCallback onMarkers;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _button(
            context,
            Icons.bookmark_border,
            context.l10n.editorMarkers,
            onMarkers,
          ),
          _button(
            context,
            Icons.image_outlined,
            context.l10n.editorCrop,
            enabled ? () => onSettings(ImageSettingsSection.framing) : null,
          ),
          _button(
            context,
            Icons.animation,
            context.l10n.motion,
            enabled ? () => onSettings(ImageSettingsSection.motion) : null,
          ),
          _button(
            context,
            Icons.text_fields,
            context.l10n.editorText,
            enabled ? () => onSettings(ImageSettingsSection.text) : null,
          ),
          _button(
            context,
            Icons.schedule,
            context.l10n.editorDisplayDuration,
            enabled ? () => onSettings(ImageSettingsSection.timing) : null,
          ),
          _button(
            context,
            Icons.music_note,
            context.l10n.musicSettings,
            onAudio,
          ),
        ],
      ),
    ),
  );
  Widget _button(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) => SizedBox(
    width: 104,
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
