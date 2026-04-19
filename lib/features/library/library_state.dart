import 'package:picturestovideos/features/library/library_media_item.dart';

class LibraryState {
  const LibraryState({
    required this.query,
    required this.selectedCategory,
    required this.items,
  });

  const LibraryState.initial()
    : query = '',
      selectedCategory = LibraryCategory.videos,
      items = _seedItems;

  final String query;
  final LibraryCategory selectedCategory;
  final List<LibraryMediaItem> items;

  List<LibraryMediaItem> get filteredItems {
    final normalizedQuery = query.trim().toLowerCase();

    return items
        .where((item) {
          if (item.category != selectedCategory) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          return item.title.toLowerCase().contains(normalizedQuery) ||
              item.tagline.toLowerCase().contains(normalizedQuery) ||
              item.importedOnLabel.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  int get totalCount => filteredItems.length;

  LibraryState copyWith({
    String? query,
    LibraryCategory? selectedCategory,
    List<LibraryMediaItem>? items,
  }) {
    return LibraryState(
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      items: items ?? this.items,
    );
  }
}

const _seedItems = [
  LibraryMediaItem(
    id: 'obsidian-range-a01',
    title: 'Obsidian_Range_A01.mp4',
    category: LibraryCategory.videos,
    durationLabel: '04:12',
    sizeLabel: '124 MB',
    tagline: 'Cinematic volcanic aerial',
    importedOnLabel: 'Dec 12, 2023',
    isFeatured: true,
  ),
  LibraryMediaItem(
    id: 'studio-lights-b07',
    title: 'Studio_Lights_B07.mp4',
    category: LibraryCategory.videos,
    durationLabel: '00:15',
    sizeLabel: '18 MB',
    tagline: 'Mixer lights macro',
    importedOnLabel: 'Jan 08, 2024',
    isFeatured: false,
  ),
  LibraryMediaItem(
    id: 'camera-lens-c02',
    title: 'Camera_Lens_C02.mp4',
    category: LibraryCategory.videos,
    durationLabel: '01:45',
    sizeLabel: '64 MB',
    tagline: 'Cinema glass reflections',
    importedOnLabel: 'Feb 03, 2024',
    isFeatured: false,
  ),
  LibraryMediaItem(
    id: 'neon-city-d04',
    title: 'Neon_City_D04.mp4',
    category: LibraryCategory.videos,
    durationLabel: '00:08',
    sizeLabel: '12 MB',
    tagline: 'Futuristic night motion blur',
    importedOnLabel: 'Feb 14, 2024',
    isFeatured: false,
  ),
  LibraryMediaItem(
    id: 'waveform-e09',
    title: 'Waveform_E09.mp4',
    category: LibraryCategory.videos,
    durationLabel: '00:52',
    sizeLabel: '31 MB',
    tagline: 'Electric blue waveform art',
    importedOnLabel: 'Mar 01, 2024',
    isFeatured: false,
  ),
  LibraryMediaItem(
    id: 'portrait-f11',
    title: 'Portrait_F11.jpg',
    category: LibraryCategory.photos,
    durationLabel: 'Photo',
    sizeLabel: '8 MB',
    tagline: 'Moody portrait frame',
    importedOnLabel: 'Mar 08, 2024',
    isFeatured: true,
  ),
  LibraryMediaItem(
    id: 'sunrise-g05',
    title: 'Sunrise_G05.jpg',
    category: LibraryCategory.photos,
    durationLabel: 'Photo',
    sizeLabel: '6 MB',
    tagline: 'Soft horizon glow',
    importedOnLabel: 'Mar 11, 2024',
    isFeatured: false,
  ),
  LibraryMediaItem(
    id: 'pulse-h03',
    title: 'Pulse_H03.gif',
    category: LibraryCategory.gifs,
    durationLabel: '00:06',
    sizeLabel: '4 MB',
    tagline: 'Looping beat pulse',
    importedOnLabel: 'Mar 16, 2024',
    isFeatured: true,
  ),
  LibraryMediaItem(
    id: 'spark-i02',
    title: 'Spark_I02.gif',
    category: LibraryCategory.gifs,
    durationLabel: '00:03',
    sizeLabel: '2 MB',
    tagline: 'Quick strobe accent',
    importedOnLabel: 'Mar 18, 2024',
    isFeatured: false,
  ),
];
