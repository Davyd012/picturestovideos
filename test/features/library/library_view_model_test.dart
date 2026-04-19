import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_view_model.dart';

void main() {
  test('searchChanged filters visible library items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(libraryViewModelProvider.notifier).searchChanged('neon');

    final state = container.read(libraryViewModelProvider);

    expect(state.filteredItems, hasLength(1));
    expect(state.filteredItems.first.title, 'Neon_City_D04.mp4');
  });

  test('categoryChanged switches the visible category', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(libraryViewModelProvider.notifier)
        .categoryChanged(LibraryCategory.photos);

    final state = container.read(libraryViewModelProvider);

    expect(state.selectedCategory, LibraryCategory.photos);
    expect(
      state.filteredItems.every(
        (item) => item.category == LibraryCategory.photos,
      ),
      isTrue,
    );
  });
}
