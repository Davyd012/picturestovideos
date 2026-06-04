import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';

class PlaybackControls extends ConsumerWidget {
  const PlaybackControls({
    required this.beatMap,
    required this.playback,
    required this.audioSourcePath,
    super.key,
  });

  final BeatMap? beatMap;
  final PlaybackState? playback;
  final String? audioSourcePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canControl =
        beatMap != null &&
        ((playback?.hasLoadedAudioSource ?? false) ||
            (audioSourcePath?.isNotEmpty ?? false));
    final isPlaying = playback?.isPlaying ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: canControl
              ? () async {
                  await _preparePlayback(ref);
                  await ref
                      .read(playbackViewModelProvider.notifier)
                      .step(const Duration(seconds: -10));
                }
              : null,
          icon: const Icon(Icons.replay_10),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: canControl ? () => _togglePlayback(ref) : null,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(isPlaying ? 'Pause' : 'Play'),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: canControl
              ? () async {
                  await _preparePlayback(ref);
                  await ref
                      .read(playbackViewModelProvider.notifier)
                      .step(const Duration(seconds: 10));
                }
              : null,
          icon: const Icon(Icons.forward_10),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: canControl
              ? () async {
                  await _preparePlayback(ref);
                  await ref
                      .read(playbackViewModelProvider.notifier)
                      .seek(Duration.zero);
                }
              : null,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }

  Future<void> _preparePlayback(WidgetRef ref) async {
    final resolvedBeatMap = beatMap;
    if (resolvedBeatMap == null) {
      return;
    }
    await ref
        .read(playbackViewModelProvider.notifier)
        .preparePlayback(
          beatMap: resolvedBeatMap,
          audioSourcePath: audioSourcePath,
        );
  }

  Future<void> _togglePlayback(WidgetRef ref) async {
    await _preparePlayback(ref);
    if (playback?.isPlaying ?? false) {
      await ref.read(playbackViewModelProvider.notifier).pause();
      return;
    }
    await ref.read(playbackViewModelProvider.notifier).play();
  }
}
