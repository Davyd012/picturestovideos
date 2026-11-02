import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';

class ImageGridCard extends ConsumerWidget {
  const ImageGridCard({
    required this.item,
    required this.isStaged,
    required this.isSelected,
    super.key,
  });

  final LibraryMediaItem item;
  final bool isStaged;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 160),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.96 + 0.04 * value, child: child),
      ),
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: item.title,
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => ref
                .read(libraryViewModelProvider.notifier)
                .itemSelectionToggled(item.id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaThumbnail(item: item),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => ref
                        .read(libraryViewModelProvider.notifier)
                        .itemSelectionToggled(item.id),
                  ),
                ),
                if (isStaged)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Chip(label: Text(context.l10n.libraryStaged)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
