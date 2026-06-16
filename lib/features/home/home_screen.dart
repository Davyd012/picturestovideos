import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:picturestovideos/features/home/home_state.dart';
import 'package:picturestovideos/features/home/home_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeViewModelProvider);

    return AppShellScaffold(
      currentRoute: AppRoutes.home,
      title: 'Home',
      actions: [
        IconButton(
          onPressed: () => ref.read(homeViewModelProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh saved media',
        ),
      ],
      body: switch (homeAsync) {
        AsyncLoading<HomeState>() => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<HomeState>(:final error) => _HomeErrorView(
          error: error,
          onRetry: () => ref.read(homeViewModelProvider.notifier).refresh(),
        ),
        AsyncData<HomeState>(:final value) => _HomeBody(state: value),
      },
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Saved media', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Reopen saved audio markers and pair them with new image selections.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (state.statusMessage != null) ...[
          const SizedBox(height: 16),
          _StatusMessage(message: state.statusMessage!),
        ],
        const SizedBox(height: 24),
        _AudioSection(
          presets: state.audioPresets,
          isOpeningAudio: state.isOpeningAudio,
        ),
        const SizedBox(height: 32),
        _ImageSection(assets: state.imageAssets),
      ],
    );
  }
}

class _AudioSection extends ConsumerWidget {
  const _AudioSection({required this.presets, required this.isOpeningAudio});

  final List<AudioMarkerPreset> presets;
  final bool isOpeningAudio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Saved audio',
          countLabel: '${presets.length} saved',
          icon: Icons.audio_file_outlined,
        ),
        const SizedBox(height: 12),
        if (presets.isEmpty)
          _EmptySavedMediaCard(
            icon: Icons.audio_file_outlined,
            title: 'No saved audio yet',
            message: 'Save markers from the editor to reuse them here.',
          )
        else
          for (final preset in presets) ...[
            _SavedAudioCard(
              preset: preset,
              isOpeningAudio: isOpeningAudio,
              onOpen: () => _openSavedAudio(context, ref, preset),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _openSavedAudio(
    BuildContext context,
    WidgetRef ref,
    AudioMarkerPreset preset,
  ) async {
    final opened = await ref
        .read(homeViewModelProvider.notifier)
        .openSavedAudio(preset);
    if (!context.mounted || !opened) {
      return;
    }
    context.appNavigator.goToImportAudio();
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.assets});

  final List<SavedImageAsset> assets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Saved assets',
          countLabel: '${assets.length} saved',
          icon: Icons.image_outlined,
        ),
        const SizedBox(height: 12),
        if (assets.isEmpty)
          _EmptySavedMediaCard(
            icon: Icons.image_outlined,
            title: 'No saved assets yet',
            message: 'Import images in the Library to list them here.',
          )
        else
          for (final asset in assets) ...[
            _SavedImageCard(asset: asset),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.countLabel,
    required this.icon,
  });

  final String title;
  final String countLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.colors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: context.textTheme.titleLarge)),
        Chip(label: Text(countLabel)),
      ],
    );
  }
}

class _SavedAudioCard extends StatelessWidget {
  const _SavedAudioCard({
    required this.preset,
    required this.isOpeningAudio,
    required this.onOpen,
  });

  final AudioMarkerPreset preset;
  final bool isOpeningAudio;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final path = preset.sourcePath;

    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.graphic_eq),
        title: Text(preset.sourceName),
        subtitle: Text(
          [
            '${preset.markerCount} marker${preset.markerCount == 1 ? '' : 's'}',
            _formatDuration(preset.duration),
            _formatDate(preset.updatedAt),
            if (path != null && path.isNotEmpty) path,
          ].join(' - '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: isOpeningAudio ? null : onOpen,
          icon: const Icon(Icons.folder_open),
          label: const Text('Open'),
        ),
      ),
    );
  }
}

class _SavedImageCard extends StatelessWidget {
  const _SavedImageCard({required this.asset});

  final SavedImageAsset asset;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.image_outlined),
        title: Text(asset.fileName),
        subtitle: Text(
          [
            _formatSize(asset.byteLength),
            _formatDate(asset.importedOn),
            asset.sourcePath,
          ].join(' - '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        leading: Icon(Icons.info_outline, color: context.colors.primary),
        title: Text(message),
      ),
    );
  }
}

class _EmptySavedMediaCard extends StatelessWidget {
  const _EmptySavedMediaCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: context.colors.primary),
            const SizedBox(height: 16),
            Text(title, style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: context.colors.error),
            const SizedBox(height: 16),
            Text(
              'Saved media could not load',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthLabels[value.month - 1];
  final day = value.day.toString().padLeft(2, '0');
  return '$month $day, ${value.year}';
}

String _formatDuration(Duration duration) {
  if (duration <= Duration.zero) {
    return 'Unknown duration';
  }
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatSize(int byteLength) {
  if (byteLength <= 0) {
    return 'Unknown size';
  }
  if (byteLength < 1024 * 1024) {
    return '${(byteLength / 1024).toStringAsFixed(1)} KB';
  }
  return '${(byteLength / (1024 * 1024)).toStringAsFixed(1)} MB';
}
