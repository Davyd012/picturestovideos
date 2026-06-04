import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/features/library/widgets/library_empty_state.dart';
import 'package:picturestovideos/features/library/widgets/library_image_grid.dart';
import 'package:picturestovideos/features/library/widgets/library_toolbar.dart';
import 'package:picturestovideos/features/library/widgets/selection_action_bar.dart';
import 'package:picturestovideos/features/library/widgets/staged_summary_card.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

class LibraryBrowseView extends ConsumerWidget {
  const LibraryBrowseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final editorSelection = ref.watch(editorMediaSelectionViewModelProvider);
    final stagedIds = editorSelection.selectedMedia
        .map((item) => item.id)
        .toSet();
    final visibleItems = state.visibleItems(stagedIds);
    final selectedItems = _selectedItems(state.items, state.selectedItemIds);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentPadding = EdgeInsets.all(
          constraints.maxWidth >= 960 ? 32 : 24,
        );

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: contentPadding.copyWith(
                    bottom: state.hasSelectedItems
                        ? 128
                        : contentPadding.bottom,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Text(
                          'Image library',
                          style: context.textTheme.headlineMedium,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverToBoxAdapter(
                        child: Text(
                          'Import images, stage the strongest frames, and send them into the beat-synced editor flow.',
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      if (!state.hasItems)
                        SliverToBoxAdapter(
                          child: LibraryEmptyState(
                            selectedCount: editorSelection.selectedCount,
                            visibleCount: visibleItems.length,
                          ),
                        )
                      else ...[
                        if (editorSelection.hasSelection) ...[
                          SliverToBoxAdapter(
                            child: StagedSummaryCard(
                              importedCount: state.totalCount,
                              visibleCount: visibleItems.length,
                              stagedCount: editorSelection.selectedCount,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        ],
                        SliverToBoxAdapter(
                          child: LibraryToolbar(
                            visibleCount: visibleItems.length,
                            stagedCount: editorSelection.selectedCount,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        if (visibleItems.isEmpty)
                          const SliverToBoxAdapter(
                            child: _NoMatchingImagesCard(),
                          )
                        else
                          LibraryImageGrid(
                            items: visibleItems,
                            stagedIds: stagedIds,
                            selectedIds: state.selectedItemIds,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (state.hasSelectedItems)
              Align(
                alignment: Alignment.bottomCenter,
                child: SelectionActionBar(selectedItems: selectedItems),
              ),
          ],
        );
      },
    );
  }

  List<LibraryMediaItem> _selectedItems(
    List<LibraryMediaItem> items,
    Set<String> selectedIds,
  ) {
    return items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
  }
}

class _NoMatchingImagesCard extends StatelessWidget {
  const _NoMatchingImagesCard();

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 40,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text('No matching images', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try another search, filter, or sort option.',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
