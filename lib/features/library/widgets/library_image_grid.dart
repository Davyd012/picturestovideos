import 'package:flutter/material.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/widgets/image_grid_card.dart';

class LibraryImageGrid extends StatelessWidget {
  const LibraryImageGrid({
    required this.items,
    required this.stagedIds,
    required this.selectedIds,
    super.key,
  });

  final List<LibraryMediaItem> items;
  final Set<String> stagedIds;
  final Set<String> selectedIds;

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
            childAspectRatio: constraints.maxWidth < 420 ? 0.66 : 0.78,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ImageGridCard(
              item: item,
              isStaged: stagedIds.contains(item.id),
              isSelected: selectedIds.contains(item.id),
            );
          },
        );
      },
    );
  }
}
