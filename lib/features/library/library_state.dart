import 'package:picturestovideos/features/library/library_media_item.dart';

class LibraryState {
  const LibraryState({
    required this.query,
    required this.folderPathInput,
    required this.items,
    required this.isImporting,
    required this.errorMessage,
    required this.statusMessage,
  });

  const LibraryState.initial()
    : query = '',
      folderPathInput = '',
      items = const [],
      isImporting = false,
      errorMessage = null,
      statusMessage = null;

  final String query;
  final String folderPathInput;
  final List<LibraryMediaItem> items;
  final bool isImporting;
  final String? errorMessage;
  final String? statusMessage;

  List<LibraryMediaItem> get filteredItems {
    final normalizedQuery = query.trim().toLowerCase();

    return items
        .where((item) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return item.title.toLowerCase().contains(normalizedQuery) ||
              // item.tagline.toLowerCase().contains(normalizedQuery) ||
              item.importedOnLabel.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  int get totalCount => items.length;
  int get visibleCount => filteredItems.length;
  bool get hasItems => items.isNotEmpty;

  LibraryState copyWith({
    String? query,
    String? folderPathInput,
    List<LibraryMediaItem>? items,
    bool? isImporting,
    String? errorMessage,
    String? statusMessage,
    bool clearError = false,
    bool clearStatusMessage = false,
  }) {
    return LibraryState(
      query: query ?? this.query,
      folderPathInput: folderPathInput ?? this.folderPathInput,
      items: items ?? this.items,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
    );
  }
}
