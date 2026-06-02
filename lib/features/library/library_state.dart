import 'package:picturestovideos/features/library/library_media_item.dart';

enum LibraryFilter { all, recent, staged, favorites }

enum LibrarySortOrder { newest, oldest, name, fileSize }

class LibraryState {
  const LibraryState({
    required this.query,
    required this.folderPathInput,
    required this.items,
    required this.selectedItemIds,
    required this.selectedFilter,
    required this.sortOrder,
    required this.isReviewingStaged,
    required this.isImporting,
    required this.errorMessage,
    required this.statusMessage,
  });

  const LibraryState.initial()
    : query = '',
      folderPathInput = '',
      items = const [],
      selectedItemIds = const {},
      selectedFilter = LibraryFilter.all,
      sortOrder = LibrarySortOrder.newest,
      isReviewingStaged = false,
      isImporting = false,
      errorMessage = null,
      statusMessage = null;

  final String query;
  final String folderPathInput;
  final List<LibraryMediaItem> items;
  final Set<String> selectedItemIds;
  final LibraryFilter selectedFilter;
  final LibrarySortOrder sortOrder;
  final bool isReviewingStaged;
  final bool isImporting;
  final String? errorMessage;
  final String? statusMessage;

  List<LibraryMediaItem> visibleItems(Set<String> stagedIds) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = items
        .where((item) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return item.title.toLowerCase().contains(normalizedQuery) ||
              item.sourcePath.toLowerCase().contains(normalizedQuery) ||
              item.importedOnLabel.toLowerCase().contains(normalizedQuery);
        })
        .where((item) {
          return switch (selectedFilter) {
            LibraryFilter.all => true,
            LibraryFilter.recent => _isRecent(item),
            LibraryFilter.staged => stagedIds.contains(item.id),
            LibraryFilter.favorites => item.isFavorite,
          };
        })
        .toList(growable: false);

    return _sortedItems(filtered);
  }

  int get totalCount => items.length;
  int get selectedCount => selectedItemIds.length;
  bool get hasItems => items.isNotEmpty;
  bool get hasSelectedItems => selectedItemIds.isNotEmpty;

  bool _isRecent(LibraryMediaItem item) {
    if (items.isEmpty) {
      return false;
    }

    final newest = items
        .map((item) => item.importedOn)
        .reduce((value, element) => value.isAfter(element) ? value : element);
    return newest.difference(item.importedOn).inDays <= 7;
  }

  List<LibraryMediaItem> _sortedItems(List<LibraryMediaItem> visibleItems) {
    final sorted = [...visibleItems];
    sorted.sort((a, b) {
      return switch (sortOrder) {
        LibrarySortOrder.newest => b.importedOn.compareTo(a.importedOn),
        LibrarySortOrder.oldest => a.importedOn.compareTo(b.importedOn),
        LibrarySortOrder.name => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
        LibrarySortOrder.fileSize => b.byteLength.compareTo(a.byteLength),
      };
    });
    return List.unmodifiable(sorted);
  }

  LibraryState copyWith({
    String? query,
    String? folderPathInput,
    List<LibraryMediaItem>? items,
    Set<String>? selectedItemIds,
    LibraryFilter? selectedFilter,
    LibrarySortOrder? sortOrder,
    bool? isReviewingStaged,
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
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      isReviewingStaged: isReviewingStaged ?? this.isReviewingStaged,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
    );
  }
}
