import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/commons/navigation/app_routes.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_state.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';
import 'package:picturestovideos/shared/widgets/app_shell_scaffold.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);

    return AppShellScaffold(
      currentRoute: AppRoutes.library,
      title: 'Library',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: state.filteredItems.isEmpty
                ? null
                : () => context.appNavigator.goToAudioEditor(),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Use in editor'),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = EdgeInsets.all(constraints.maxWidth >= 960 ? 32 : 24);

          return ListView(
            padding: padding,
            children: [
              Text('Media library', style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Browse saved assets, narrow by media type, and send the best match into the editor flow.',
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _LibraryToolbar(state: state),
              const SizedBox(height: 24),
              if (state.filteredItems.isEmpty)
                _EmptyLibraryState(selectedCategory: state.selectedCategory)
              else
                _LibraryGrid(items: state.filteredItems),
              const SizedBox(height: 24),
              const _QuickAddActions(),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryToolbar extends ConsumerWidget {
  const _LibraryToolbar({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: ref
                  .read(libraryViewModelProvider.notifier)
                  .searchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search media, tags, or dates',
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<LibraryCategory>(
                segments: const [
                  ButtonSegment(
                    value: LibraryCategory.videos,
                    label: Text('Videos'),
                  ),
                  ButtonSegment(
                    value: LibraryCategory.photos,
                    label: Text('Photos'),
                  ),
                  ButtonSegment(
                    value: LibraryCategory.gifs,
                    label: Text('Giphy'),
                  ),
                ],
                selected: {state.selectedCategory},
                onSelectionChanged: (selection) {
                  ref
                      .read(libraryViewModelProvider.notifier)
                      .categoryChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _LibrarySummaryChip(
                  label: 'Visible assets',
                  value: '${state.totalCount}',
                ),
                _LibrarySummaryChip(
                  label: 'Category',
                  value: _categoryLabel(state.selectedCategory),
                ),
                _LibrarySummaryChip(
                  label: 'Search',
                  value: state.query.trim().isEmpty ? 'All items' : state.query,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.videos => 'Videos',
      LibraryCategory.photos => 'Photos',
      LibraryCategory.gifs => 'Giphy',
    };
  }
}

class _LibrarySummaryChip extends StatelessWidget {
  const _LibrarySummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({required this.items});

  final List<LibraryMediaItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          > 1200 => 5,
          > 900 => 4,
          > 640 => 3,
          _ => 2,
        };

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            return _LibraryCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.item});

  final LibraryMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.appNavigator.goToAudioEditor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ColoredBox(
                color: item.isFeatured
                    ? context.colors.primaryContainer
                    : context.colors.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    _categoryIcon(item.category),
                    size: 40,
                    color: item.isFeatured
                        ? context.colors.onPrimaryContainer
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text(item.durationLabel)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.importedOnLabel} • ${item.sizeLabel}',
                    style: context.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => context.appNavigator.goToAudioEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Quick add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.videos => Icons.ondemand_video,
      LibraryCategory.photos => Icons.image,
      LibraryCategory.gifs => Icons.gif_box,
    };
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.selectedCategory});

  final LibraryCategory selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = switch (selectedCategory) {
      LibraryCategory.videos => 'videos',
      LibraryCategory.photos => 'photos',
      LibraryCategory.gifs => 'gifs',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 32, color: context.colors.primary),
            const SizedBox(height: 16),
            Text('No matching assets', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try a broader search or switch categories to see more $categoryLabel.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddActions extends StatelessWidget {
  const _QuickAddActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick add actions', style: context.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToImportAudio(),
                  icon: const Icon(Icons.audio_file_outlined),
                  label: const Text('Import more audio'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToAudioEditor(),
                  icon: const Icon(Icons.tune),
                  label: const Text('Open editor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.appNavigator.goToDownload(),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Go to export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
