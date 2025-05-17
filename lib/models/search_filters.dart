/// Base class for all search filters
abstract class SearchFilter {
  String get displayName;
  bool get isActive;
}

/// Filters for song search
class SongSearchFilters {
  // Artist filter
  String? artistId;
  String? artistName;

  // Language filter
  String? languageId;
  String? languageName;

  // Tags filter (multiple tags can be selected)
  List<String> tags = [];

  // Difficulty filter
  String? difficulty;

  // Key filter
  String? key;

  // Capo filter
  int? capo;

  // Time signature filter
  String? timeSignature;

  // Sort options
  String? sortBy; // 'newest', 'mostViewed', 'alphabetical'

  // Clear all filters
  void clear() {
    artistId = null;
    artistName = null;
    languageId = null;
    languageName = null;
    tags = [];
    difficulty = null;
    key = null;
    capo = null;
    timeSignature = null;
    sortBy = null;
  }

  // Check if any filter is active
  bool get isActive =>
    artistId != null ||
    languageId != null ||
    tags.isNotEmpty ||
    difficulty != null ||
    key != null ||
    capo != null ||
    timeSignature != null ||
    sortBy != null;

  // Convert to query parameters for API
  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};

    if (artistId != null) params['artistId'] = artistId!;
    if (languageId != null) params['languageId'] = languageId!;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');
    if (difficulty != null) params['difficulty'] = difficulty!;
    if (key != null) params['key'] = key!;
    if (capo != null) params['capo'] = capo.toString();
    if (timeSignature != null) params['timeSignature'] = timeSignature!;
    if (sortBy != null) params['sortBy'] = sortBy!;

    return params;
  }
}

/// Filters for artist search
class ArtistSearchFilters {
  // Sort options
  String? sortBy; // 'alphabetical', 'mostSongs', 'newest'

  // Clear all filters
  void clear() {
    sortBy = null;
  }

  // Check if any filter is active
  bool get isActive => sortBy != null;

  // Convert to query parameters for API
  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};

    if (sortBy != null) params['sortBy'] = sortBy!;

    return params;
  }
}

/// Filters for collection search
class CollectionSearchFilters {
  // Sort options
  String? sortBy; // 'newest', 'mostLiked', 'mostViewed', 'alphabetical'

  // Clear all filters
  void clear() {
    sortBy = null;
  }

  // Check if any filter is active
  bool get isActive => sortBy != null;

  // Convert to query parameters for API
  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};

    if (sortBy != null) params['sortBy'] = sortBy!;

    return params;
  }
}

/// Filter option for dropdown menus
class FilterOption implements SearchFilter {
  final String id;
  @override
  final String displayName;
  @override
  final bool isActive;

  FilterOption({
    required this.id,
    required this.displayName,
    this.isActive = false,
  });
}

/// Predefined lists of filter options
class FilterOptions {
  // Song difficulty options
  static List<FilterOption> difficulties = [
    FilterOption(id: 'BEGINNER', displayName: 'Beginner'),
    FilterOption(id: 'EASY', displayName: 'Easy'),
    FilterOption(id: 'MEDIUM', displayName: 'Medium'),
    FilterOption(id: 'HARD', displayName: 'Hard'),
    FilterOption(id: 'EXPERT', displayName: 'Expert'),
  ];

  // Song key options
  static List<FilterOption> keys = [
    FilterOption(id: 'A', displayName: 'A'),
    FilterOption(id: 'A#', displayName: 'A#'),
    FilterOption(id: 'B', displayName: 'B'),
    FilterOption(id: 'C', displayName: 'C'),
    FilterOption(id: 'C#', displayName: 'C#'),
    FilterOption(id: 'D', displayName: 'D'),
    FilterOption(id: 'D#', displayName: 'D#'),
    FilterOption(id: 'E', displayName: 'E'),
    FilterOption(id: 'F', displayName: 'F'),
    FilterOption(id: 'F#', displayName: 'F#'),
    FilterOption(id: 'G', displayName: 'G'),
    FilterOption(id: 'G#', displayName: 'G#'),
    FilterOption(id: 'Am', displayName: 'Am'),
    FilterOption(id: 'A#m', displayName: 'A#m'),
    FilterOption(id: 'Bm', displayName: 'Bm'),
    FilterOption(id: 'Cm', displayName: 'Cm'),
    FilterOption(id: 'C#m', displayName: 'C#m'),
    FilterOption(id: 'Dm', displayName: 'Dm'),
    FilterOption(id: 'D#m', displayName: 'D#m'),
    FilterOption(id: 'Em', displayName: 'Em'),
    FilterOption(id: 'Fm', displayName: 'Fm'),
    FilterOption(id: 'F#m', displayName: 'F#m'),
    FilterOption(id: 'Gm', displayName: 'Gm'),
    FilterOption(id: 'G#m', displayName: 'G#m'),
  ];

  // Time signature options
  static List<FilterOption> timeSignatures = [
    FilterOption(id: '4/4', displayName: '4/4'),
    FilterOption(id: '3/4', displayName: '3/4'),
    FilterOption(id: '6/8', displayName: '6/8'),
    FilterOption(id: '2/4', displayName: '2/4'),
    FilterOption(id: '5/4', displayName: '5/4'),
    FilterOption(id: '7/8', displayName: '7/8'),
    FilterOption(id: '12/8', displayName: '12/8'),
  ];

  // Capo options
  static List<FilterOption> capos = List.generate(
    12,
    (index) => FilterOption(id: index.toString(), displayName: 'Capo $index')
  );

  // Song sort options
  static List<FilterOption> songSortOptions = [
    FilterOption(id: 'alphabetical', displayName: 'A-Z'),
    FilterOption(id: 'newest', displayName: 'Newest'),
    FilterOption(id: 'mostViewed', displayName: 'Most Viewed'),
  ];

  // Artist sort options
  static List<FilterOption> artistSortOptions = [
    FilterOption(id: 'alphabetical', displayName: 'A-Z'),
    FilterOption(id: 'mostSongs', displayName: 'Most Songs'),
    FilterOption(id: 'newest', displayName: 'Newest'),
  ];

  // Collection sort options
  static List<FilterOption> collectionSortOptions = [
    FilterOption(id: 'alphabetical', displayName: 'A-Z'),
    FilterOption(id: 'newest', displayName: 'Newest'),
    FilterOption(id: 'mostLiked', displayName: 'Most Liked'),
    FilterOption(id: 'mostViewed', displayName: 'Most Viewed'),
  ];
}
