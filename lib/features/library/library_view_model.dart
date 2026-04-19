import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/features/library/library_media_item.dart';
import 'package:picturestovideos/features/library/library_state.dart';

final libraryViewModelProvider =
    NotifierProvider.autoDispose<LibraryViewModel, LibraryState>(
      LibraryViewModel.new,
    );

class LibraryViewModel extends Notifier<LibraryState> {
  @override
  LibraryState build() {
    return const LibraryState.initial();
  }

  void searchChanged(String query) {
    state = state.copyWith(query: query);
  }

  void categoryChanged(LibraryCategory category) {
    state = state.copyWith(selectedCategory: category);
  }
}
