import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/editor/editor_media_selection_view_model.dart';
import 'package:picturestovideos/features/editor/widgets/media_thumbnail.dart';
import 'package:picturestovideos/features/timeline/timeline_view_model.dart';
import 'package:picturestovideos/shared/extensions/build_context_localization_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_navigation_extensions.dart';
import 'package:picturestovideos/shared/extensions/build_context_theme_extensions.dart';

final queueSelectionProvider = NotifierProvider<QueueSelection, List<String>>(
  QueueSelection.new,
);

class QueueSelection extends Notifier<List<String>> {
  @override
  List<String> build() => const [];
  void toggle(String id) => state = state.contains(id)
      ? List.unmodifiable(state.where((value) => value != id))
      : List.unmodifiable([...state, id]);
  void selectAll(List<String> ids) => state = List.unmodifiable(ids);
  void clear() => state = const [];
}

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(editorMediaSelectionViewModelProvider);
    final items = queue.selectedMedia;
    final ids = items.map((item) => item.id).toSet();
    final selected = ref
        .watch(queueSelectionProvider)
        .where(ids.contains)
        .toList();
    final all = items.isNotEmpty && selected.length == items.length;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.appNavigator.maybePop()),
        title: Row(
          children: [
            Flexible(
              child: Text(
                context.l10n.editorQueueTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Badge(label: Text('${items.length}')),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: all,
                  onChanged: (_) => all
                      ? ref.read(queueSelectionProvider.notifier).clear()
                      : ref
                            .read(queueSelectionProvider.notifier)
                            .selectAll(items.map((e) => e.id).toList()),
                ),
                Expanded(child: Text(context.l10n.editorSelectAll)),
                IconButton(
                  tooltip: context.l10n.reverseCurrent,
                  onPressed: items.length < 2
                      ? null
                      : () => ref
                            .read(
                              editorMediaSelectionViewModelProvider.notifier,
                            )
                            .reverseSequence(),
                  icon: const Icon(Icons.swap_vert),
                ),
              ],
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(context.l10n.queuedImages(0)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.25,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final order = selected.indexOf(item.id);
                        return Semantics(
                          selected: order >= 0,
                          button: true,
                          label: item.title,
                          child: InkWell(
                            key: ValueKey(item.id),
                            onTap: () => ref
                                .read(queueSelectionProvider.notifier)
                                .toggle(item.id),
                            onLongPress: () => showDialog<void>(
                              context: context,
                              builder: (context) => Dialog.fullscreen(
                                child: SafeArea(
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child: MediaThumbnail(
                                            path: item.sourcePath.isNotEmpty
                                                ? item.sourcePath
                                                : null,
                                            item: item.sourcePath.isEmpty
                                                ? item
                                                : null,
                                            fit: BoxFit.contain,
                                            cacheWidth: null,
                                          ),
                                        ),
                                      ),
                                      const Align(
                                        alignment: Alignment.topRight,
                                        child: CloseButton(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  MediaThumbnail(item: item),
                                  if (order >= 0)
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.colors.primary,
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: order >= 0
                                          ? context.colors.primary
                                          : context
                                                .colors
                                                .surfaceContainerHighest,
                                      foregroundColor: order >= 0
                                          ? context.colors.onPrimary
                                          : context.colors.onSurface,
                                      child: Icon(
                                        order >= 0
                                            ? Icons.check
                                            : Icons.circle_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  if (order >= 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: context.colors.surface,
                                        child: Text('${order + 1}'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          final byId = {
                            for (final item in items) item.id: item,
                          };
                          final added = ref
                              .read(timelineViewModelProvider.notifier)
                              .appendQueuedMedia(
                                items: [
                                  for (final id in selected)
                                    if (byId[id] != null) byId[id]!,
                                ],
                                imageFits: queue.selectedImageFits,
                                cropTransforms: queue.selectedCropTransforms,
                              );
                          ref.read(queueSelectionProvider.notifier).clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added == 0
                                    ? context.l10n.editorAlreadyOnTimeline
                                    : context.l10n.editorAddedCount(added),
                              ),
                            ),
                          );
                          context.appNavigator.maybePop();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.editorAddSelected(selected.length)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
