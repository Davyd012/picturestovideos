enum LibraryCategory { videos, photos, gifs }

class LibraryMediaItem {
  const LibraryMediaItem({
    required this.id,
    required this.title,
    required this.category,
    required this.durationLabel,
    required this.sizeLabel,
    required this.tagline,
    required this.importedOnLabel,
    required this.isFeatured,
  });

  final String id;
  final String title;
  final LibraryCategory category;
  final String durationLabel;
  final String sizeLabel;
  final String tagline;
  final String importedOnLabel;
  final bool isFeatured;
}
