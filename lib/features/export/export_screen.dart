import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/preview/domain/build_preview_video_result.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:picturestovideos/core/timeline/domain/media_track_clip_payload.dart';
import 'package:picturestovideos/features/beat_map/beat_map_state.dart';
import 'package:picturestovideos/features/beat_map/beat_map_view_model.dart';
import 'package:picturestovideos/features/audio_import/audio_import_view_model.dart';
import 'package:picturestovideos/features/export/export_state.dart';
import 'package:picturestovideos/features/export/export_view_model.dart';
import 'package:picturestovideos/features/playback/playback_state.dart';
import 'package:picturestovideos/features/playback/playback_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beatMapState = ref.watch(beatMapViewModelProvider);
    final timelineState = ref.watch(timelineViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);
    final importState = ref.watch(audioImportViewModelProvider);
    final exportState = ref.watch(exportViewModelProvider);

    final project = timelineState.asData?.value.project;
    final beatMap = _resolvedBeatMap(
      project: project,
      beatMapState: beatMapState,
      playbackState: playbackState,
    );
    final playback = playbackState.asData?.value;
    final audioSourcePath = importState.asData?.value.source?.path;
    final exportClips = project == null
        ? const <MediaTrackClipPayload>[]
        : ref
              .read(resolvePreviewClipsUseCaseProvider)
              .call(beatMap: project.beatMap, project: project);
    final hasExportableClips = exportClips.isNotEmpty;
    final canRender = hasExportableClips && !exportState.isRendering;

    return AppShellScaffold(
      currentRoute: AppRoutes.download,
      title: 'Export / Download',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: canRender
                ? () => ref
                      .read(exportViewModelProvider.notifier)
                      .renderExport(
                        project: project,
                        audioSourcePath: audioSourcePath,
                      )
                : null,
            icon: const Icon(Icons.download),
            label: Text(exportState.isRendering ? 'Rendering' : 'Export'),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = EdgeInsets.all(constraints.maxWidth >= 960 ? 32 : 24);
          final showSidePanel = constraints.maxWidth >= 1180;

          return ListView(
            padding: padding,
            children: [
              if (showSidePanel)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _ExportMainColumn(
                        project: project,
                        beatMap: beatMap,
                        playback: playback,
                        hasExportableClips: hasExportableClips,
                        exportState: exportState,
                        onRender: () => ref
                            .read(exportViewModelProvider.notifier)
                            .renderExport(
                              project: project,
                              audioSourcePath: audioSourcePath,
                            ),
                        onSave: () => ref
                            .read(exportViewModelProvider.notifier)
                            .saveToGallery(),
                        onShare: () => ref
                            .read(exportViewModelProvider.notifier)
                            .shareExport(
                              projectName:
                                  project?.name ?? 'Pictures To Videos Export',
                            ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _ExportSidePanel(
                        project: project,
                        beatMap: beatMap,
                        hasExportableClips: hasExportableClips,
                      ),
                    ),
                  ],
                )
              else ...[
                _ExportMainColumn(
                  project: project,
                  beatMap: beatMap,
                  playback: playback,
                  hasExportableClips: hasExportableClips,
                  exportState: exportState,
                  onRender: () => ref
                      .read(exportViewModelProvider.notifier)
                      .renderExport(
                        project: project,
                        audioSourcePath: audioSourcePath,
                      ),
                  onSave: () => ref
                      .read(exportViewModelProvider.notifier)
                      .saveToGallery(),
                  onShare: () => ref
                      .read(exportViewModelProvider.notifier)
                      .shareExport(
                        projectName:
                            project?.name ?? 'Pictures To Videos Export',
                      ),
                ),
                const SizedBox(height: 24),
                _ExportSidePanel(
                  project: project,
                  beatMap: beatMap,
                  hasExportableClips: hasExportableClips,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  BeatMap? _resolvedBeatMap({
    required ProjectTimeline? project,
    required AsyncValue<BeatMapState> beatMapState,
    required AsyncValue<PlaybackState> playbackState,
  }) {
    if (project != null && project.beatMap.beats.isNotEmpty) {
      return project.beatMap;
    }

    final playbackBeatMap = playbackState.asData?.value.beatMap;
    if (playbackBeatMap != null && playbackBeatMap.beats.isNotEmpty) {
      return playbackBeatMap;
    }

    final stateBeatMap = beatMapState.asData?.value.beatMap;
    if (stateBeatMap != null && stateBeatMap.beats.isNotEmpty) {
      return stateBeatMap;
    }

    return null;
  }
}

class _ExportMainColumn extends StatelessWidget {
  const _ExportMainColumn({
    required this.project,
    required this.beatMap,
    required this.playback,
    required this.exportState,
    required this.hasExportableClips,
    required this.onRender,
    required this.onSave,
    required this.onShare,
  });

  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final PlaybackState? playback;
  final ExportState exportState;
  final bool hasExportableClips;
  final VoidCallback onRender;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewSummaryCard(
          project: project,
          beatMap: beatMap,
          playback: playback,
          exportState: exportState,
          hasExportableClips: hasExportableClips,
        ),
        const SizedBox(height: 24),
        _ExportActionCard(
          project: project,
          beatMap: beatMap,
          exportState: exportState,
          hasExportableClips: hasExportableClips,
          onRender: onRender,
          onSave: onSave,
        ),
        const SizedBox(height: 24),
        _ShareActionsCard(exportState: exportState, onShare: onShare),
      ],
    );
  }
}

class _PreviewSummaryCard extends StatelessWidget {
  const _PreviewSummaryCard({
    required this.project,
    required this.beatMap,
    required this.playback,
    required this.exportState,
    required this.hasExportableClips,
  });

  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final PlaybackState? playback;
  final ExportState exportState;
  final bool hasExportableClips;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: project?.template.aspectRatio.value ?? 16 / 9,
        child: Stack(
          children: [
            ColoredBox(color: context.colors.surfaceContainerHighest),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      !hasExportableClips
                          ? 'Preview unavailable'
                          : 'Image preview summary',
                    ),
                  ),
                  const Spacer(),
                  Align(
                    child: Icon(
                      !hasExportableClips
                          ? Icons.hide_image_outlined
                          : Icons.movie,
                      size: 72,
                      color: context.colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project?.name ?? 'Midnight_Obsidian_V4',
                              style: context.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              !hasExportableClips
                                  ? 'Add timed image clips before exporting the final output.'
                                  : exportState.statusMessage,
                              style: context.textTheme.bodyLarge,
                            ),
                            if (exportState.result != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                exportState.result!.outputPath,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _durationLabel(project, beatMap, playback),
                        style: context.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(
    ProjectTimeline? project,
    BeatMap? beatMap,
    PlaybackState? playback,
  ) {
    final sourceDuration = playback?.sourceDuration;
    final mediaEnd = _projectMediaEnd(project);
    final beatEnd = beatMap?.beats.isNotEmpty ?? false
        ? beatMap!.beats.last.time
        : Duration.zero;
    final end = sourceDuration ?? (mediaEnd > beatEnd ? mediaEnd : beatEnd);
    final minutes = end.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = end.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (end.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds:$millis';
  }
}

class _ExportActionCard extends StatelessWidget {
  const _ExportActionCard({
    required this.project,
    required this.beatMap,
    required this.exportState,
    required this.hasExportableClips,
    required this.onRender,
    required this.onSave,
  });

  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final ExportState exportState;
  final bool hasExportableClips;
  final VoidCallback onRender;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final details = _ExportDetails.fromData(project: project, beatMap: beatMap);
    final canRender =
        project != null &&
        hasExportableClips &&
        !exportState.isRendering &&
        !exportState.isSaving &&
        !exportState.isSharing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finalize output', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                FilledButton.icon(
                  onPressed: canRender ? onRender : null,
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: Text(exportState.isRendering ? 'Rendering' : 'Render'),
                ),
                FilledButton.tonalIcon(
                  onPressed: exportState.canSave ? onSave : null,
                  icon: const Icon(Icons.download),
                  label: Text(
                    exportState.isSaving ? 'Saving' : 'Export to gallery',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${details.fileSizeLabel} • ${details.codecLabel}',
              style: context.textTheme.bodyMedium,
            ),
            if (exportState.isFailure) ...[
              const SizedBox(height: 12),
              Text(
                exportState.errorMessage ?? exportState.statusMessage,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (exportState.hasRenderProgress) ...[
              const SizedBox(height: 24),
              _ExportProgressPanel(progress: exportState.renderProgress!),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _DetailTile(
                  label: 'Resolution',
                  value: details.resolutionLabel,
                ),
                _DetailTile(label: 'Template', value: details.templateLabel),
                _DetailTile(label: 'Frame rate', value: details.frameRateLabel),
                _DetailTile(label: 'Codec', value: details.codecLabel),
                _DetailTile(
                  label: 'Estimated size',
                  value: details.fileSizeLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportProgressPanel extends StatelessWidget {
  const _ExportProgressPanel({required this.progress});

  final BuildPreviewVideoProgress progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Export progress ${progress.percent} percent, ${progress.stepLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.currentStepLabel,
                  style: context.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${progress.percent}%',
                style: context.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.value),
          const SizedBox(height: 8),
          Text(progress.stepLabel, style: context.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ShareActionsCard extends StatelessWidget {
  const _ShareActionsCard({required this.exportState, required this.onShare});

  final ExportState exportState;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share actions', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                FilledButton.tonalIcon(
                  onPressed: exportState.canShare ? onShare : null,
                  icon: const Icon(Icons.share),
                  label: Text(exportState.isSharing ? 'Sharing' : 'Share'),
                ),
                OutlinedButton.icon(
                  onPressed: exportState.canShare ? onShare : null,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Instagram'),
                ),
                OutlinedButton.icon(
                  onPressed: exportState.canShare ? onShare : null,
                  icon: const Icon(Icons.music_video_outlined),
                  label: const Text('TikTok'),
                ),
                OutlinedButton.icon(
                  onPressed: exportState.canShare ? onShare : null,
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSidePanel extends StatelessWidget {
  const _ExportSidePanel({
    required this.project,
    required this.beatMap,
    required this.hasExportableClips,
  });

  final ProjectTimeline? project;
  final BeatMap? beatMap;
  final bool hasExportableClips;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project summary', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                _StatusTile(
                  label: 'Project',
                  value: project?.name ?? 'Not ready',
                ),
                _StatusTile(
                  label: 'Tracks',
                  value: project == null ? '0' : '${project!.tracks.length}',
                ),
                _StatusTile(
                  label: 'Template',
                  value: project?.template.name ?? 'Default',
                ),
                _StatusTile(
                  label: 'Beat markers',
                  value: beatMap == null ? '0' : '${beatMap!.beats.length}',
                ),
                _StatusTile(
                  label: 'Average interval',
                  value: beatMap == null
                      ? 'n/a'
                      : '${beatMap!.averageBeatInterval.inMilliseconds} ms',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next steps', style: context.textTheme.titleLarge),
                const SizedBox(height: 16),
                if (!hasExportableClips) ...[
                  Text(
                    'Add timed image clips before exporting.',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.appNavigator.goToAudioEditor(),
                    icon: const Icon(Icons.tune),
                    label: const Text('Return to editor'),
                  ),
                ] else ...[
                  Text(
                    'The export package is staged. You can save locally or pass the result into social flows.',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.appNavigator.goToAudioEditor(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to editor'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
  }
}

class _ExportDetails {
  const _ExportDetails({
    required this.resolutionLabel,
    required this.frameRateLabel,
    required this.codecLabel,
    required this.fileSizeLabel,
    required this.templateLabel,
  });

  final String resolutionLabel;
  final String frameRateLabel;
  final String codecLabel;
  final String fileSizeLabel;
  final String templateLabel;

  factory _ExportDetails.fromData({
    required ProjectTimeline? project,
    required BeatMap? beatMap,
  }) {
    if (project == null) {
      return const _ExportDetails(
        resolutionLabel: '1080 x 1920',
        frameRateLabel: '30 fps',
        codecLabel: 'MP4',
        fileSizeLabel: 'Unavailable',
        templateLabel: 'Default',
      );
    }

    final sizeEstimate =
        96 + ((beatMap?.beats.length ?? 0) * 3) + (project.tracks.length * 8);

    return _ExportDetails(
      resolutionLabel: project.template.aspectRatio.exportResolutionLabel,
      frameRateLabel: '30 fps',
      codecLabel: 'MP4 video',
      fileSizeLabel: '$sizeEstimate MB',
      templateLabel: project.template.name,
    );
  }
}

Duration _projectMediaEnd(ProjectTimeline? project) {
  var end = Duration.zero;
  if (project == null) {
    return end;
  }
  for (final track in project.tracks) {
    for (final event in track.events) {
      final payload = event.payload;
      if (payload is MediaTrackClipPayload && payload.end > end) {
        end = payload.end;
      }
    }
  }
  return end;
}
