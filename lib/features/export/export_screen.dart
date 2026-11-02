import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/composition/domain/video_composition.dart';
import 'package:picturestovideos/core/preview/application/resolve_preview_clips_use_case.dart';
import 'package:picturestovideos/core/preview/data/render_capability_repository.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/features/export/export_state.dart';
import 'package:picturestovideos/features/export/export_view_model.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(timelineViewModelProvider, (previous, next) {
      if (previous?.asData?.value.project != next.asData?.value.project) {
        ref.read(exportViewModelProvider.notifier).projectChanged();
      }
    });
    final project = ref.watch(timelineViewModelProvider).asData?.value.project;
    final state = ref.watch(exportViewModelProvider);
    final capabilities = ref.watch(renderCapabilitiesProvider);
    final clips = project == null
        ? null
        : ref
              .read(resolvePreviewClipsUseCaseProvider)
              .call(beatMap: project.beatMap, project: project);
    final composition = project == null
        ? null
        : VideoComposition.fromProject(
            project: project,
            committedClips: clips!,
            width: project.template.aspectRatio.exportWidth,
            height: project.template.aspectRatio.exportHeight,
            frameRate: 30,
            audioSourcePath: project.audioSourcePath,
          ).quantizedForOutput();
    final empty = composition == null || composition.clips.isEmpty;
    final valid = !empty && composition.validate().isEmpty;
    final issue = valid
        ? capabilities.asData?.value.issuesFor(composition).firstOrNull
        : null;
    final message = !valid
        ? null
        : capabilities.isLoading
        ? context.l10n.exportCapabilityChecking
        : capabilities.hasError
        ? context.l10n.exportCapabilityProbeFailed
        : issue == null
        ? null
        : _capabilityMessage(context, issue);
    final busy =
        state.isValidating ||
        state.isRendering ||
        state.isSaving ||
        state.isSharing;
    final matchesProject = identical(state.project, project);
    final vm = ref.read(exportViewModelProvider.notifier);

    return AppShellScaffold(
      currentRoute: AppRoutes.download,
      title: context.l10n.exportTitle,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!valid)
            _EmptyExportCard(empty: empty)
          else ...[
            _ExportSettings(composition: composition),
            const SizedBox(height: 24),
            if (message != null)
              Semantics(liveRegion: true, child: Text(message)),
            if (state.isFailure)
              Semantics(
                liveRegion: true,
                child: Text(
                  state.capabilityIssue == null
                      ? context.l10n.exportFailed
                      : _capabilityMessage(context, state.capabilityIssue!),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            if (state.isValidating || state.isRendering) ...[
              const SizedBox(height: 16),
              Semantics(
                label: context.l10n.exportProgress,
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isValidating
                          ? context.l10n.exportValidating
                          : context.l10n.exportRendering,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: state.renderProgress?.value),
                    if (state.renderProgress != null)
                      Text('${state.renderProgress!.percent}%'),
                  ],
                ),
              ),
            ],
            if (state.isCancelled) Text(context.l10n.exportCancelled),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: state.isReady && matchesProject
                  ? Semantics(
                      key: const ValueKey('complete'),
                      liveRegion: true,
                      child: Text(
                        state.status == ExportStatus.saved
                            ? context.l10n.exportSaved
                            : context.l10n.exportComplete,
                        style: context.textTheme.titleMedium,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('pending')),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: message == null && !busy
                  ? () => vm.renderExport(
                      project: project,
                      audioSourcePath: project?.audioSourcePath,
                    )
                  : null,
              icon: const Icon(Icons.movie_creation_outlined),
              label: Text(context.l10n.exportTitle),
            ),
            if (state.isRendering)
              OutlinedButton(
                onPressed: state.isCancelling ? null : vm.cancelRender,
                child: Text(
                  state.isCancelling
                      ? context.l10n.cancellingExport
                      : context.l10n.cancelExport,
                ),
              ),
            if (state.result != null && matchesProject) ...[
              OutlinedButton.icon(
                onPressed: state.canSave ? vm.saveToGallery : null,
                icon: const Icon(Icons.download),
                label: Text(
                  state.isSaving
                      ? context.l10n.exportSaving
                      : context.l10n.exportSave,
                ),
              ),
              OutlinedButton.icon(
                onPressed: state.canShare
                    ? () => vm.shareExport(projectName: project!.name)
                    : null,
                icon: const Icon(Icons.share),
                label: Text(
                  state.isSharing
                      ? context.l10n.exportSharing
                      : context.l10n.exportShare,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyExportCard extends StatelessWidget {
  const _EmptyExportCard({required this.empty});
  final bool empty;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.hide_image_outlined,
            size: 64,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            empty ? context.l10n.exportEmpty : context.l10n.exportInvalid,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
          if (empty) ...[
            const SizedBox(height: 16),
            Text(context.l10n.exportEmptyHelp, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => empty
                ? context.appNavigator.goToLibrary()
                : context.appNavigator.goToAudioEditor(),
            child: Text(
              empty ? context.l10n.exportGoImages : context.l10n.openEditor,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExportSettings extends StatelessWidget {
  const _ExportSettings({required this.composition});
  final VideoComposition composition;
  @override
  Widget build(BuildContext context) {
    final duration = composition.duration;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.exportSettings, style: context.textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(context.l10n.exportFormat),
                trailing: const Text('MP4'),
              ),
              ListTile(
                title: Text(context.l10n.exportResolution),
                trailing: Text('${composition.width} × ${composition.height}'),
              ),
              ListTile(
                title: Text(context.l10n.exportFrameRate),
                trailing: Text('${composition.frameRate} fps'),
              ),
              ListTile(
                title: Text(context.l10n.exportDuration),
                trailing: Text('$minutes:$seconds'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _capabilityMessage(BuildContext context, RenderCapabilityIssue issue) =>
    switch (issue) {
      RenderCapabilityIssue.unsupportedPlatform =>
        context.l10n.exportUnsupportedPlatform,
      RenderCapabilityIssue.missingFfmpeg => context.l10n.exportMissingFfmpeg,
      RenderCapabilityIssue.probeFailed =>
        context.l10n.exportCapabilityProbeFailed,
      RenderCapabilityIssue.missingFilter => context.l10n.exportMissingFilter,
      RenderCapabilityIssue.missingEncoder => context.l10n.exportMissingEncoder,
      RenderCapabilityIssue.missingMuxer => context.l10n.exportMissingMuxer,
      RenderCapabilityIssue.missingFont => context.l10n.exportMissingFont,
    };
