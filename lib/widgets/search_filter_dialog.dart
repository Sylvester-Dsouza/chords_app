import 'package:flutter/material.dart';
import '../models/search_filters.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/collection.dart';
import '../config/theme.dart';

class SearchFilterDialog extends StatefulWidget {
  final int tabIndex; // 0 = Songs, 1 = Artists, 2 = Collections
  final SongSearchFilters? songFilters;
  final ArtistSearchFilters? artistFilters;
  final CollectionSearchFilters? collectionFilters;
  final Function(SongSearchFilters) onSongFiltersApplied;
  final Function(ArtistSearchFilters) onArtistFiltersApplied;
  final Function(CollectionSearchFilters) onCollectionFiltersApplied;

  // Add data lists to generate dynamic filters
  final List<Song>? availableSongs;
  final List<Artist>? availableArtists;
  final List<Collection>? availableCollections;

  const SearchFilterDialog({
    super.key,
    required this.tabIndex,
    this.songFilters,
    this.artistFilters,
    this.collectionFilters,
    required this.onSongFiltersApplied,
    required this.onArtistFiltersApplied,
    required this.onCollectionFiltersApplied,
    this.availableSongs,
    this.availableArtists,
    this.availableCollections,
  });

  @override
  State<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<SearchFilterDialog> {
  late SongSearchFilters _songFilters;
  late ArtistSearchFilters _artistFilters;
  late CollectionSearchFilters _collectionFilters;

  @override
  void initState() {
    super.initState();
    _songFilters = widget.songFilters ?? SongSearchFilters();
    _artistFilters = widget.artistFilters ?? ArtistSearchFilters();
    _collectionFilters = widget.collectionFilters ?? CollectionSearchFilters();
  }

  // Generate dynamic filter options based on available data
  List<FilterOption> _getAvailableKeys() {
    if (widget.availableSongs == null || widget.availableSongs!.isEmpty) {
      return [];
    }

    final availableKeys = widget.availableSongs!
        .map((song) => song.key)
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList();

    availableKeys.sort();

    return availableKeys
        .map((key) => FilterOption(id: key, displayName: key))
        .toList();
  }

  List<FilterOption> _getAvailableDifficulties() {
    if (widget.availableSongs == null || widget.availableSongs!.isEmpty) {
      return [];
    }

    final availableDifficulties = widget.availableSongs!
        .map((song) => song.difficulty)
        .where((difficulty) => difficulty != null && difficulty.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    // Sort by difficulty order
    final difficultyOrder = ['BEGINNER', 'EASY', 'MEDIUM', 'HARD', 'EXPERT'];
    availableDifficulties.sort((a, b) {
      final aIndex = difficultyOrder.indexOf(a.toUpperCase());
      final bIndex = difficultyOrder.indexOf(b.toUpperCase());
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    return availableDifficulties
        .map((difficulty) => FilterOption(
              id: difficulty.toUpperCase(),
              displayName: _formatDifficultyName(difficulty)
            ))
        .toList();
  }

  List<FilterOption> _getAvailableCapos() {
    if (widget.availableSongs == null || widget.availableSongs!.isEmpty) {
      return [];
    }

    final availableCapos = widget.availableSongs!
        .map((song) => song.capo)
        .where((capo) => capo != null && capo > 0)
        .cast<int>()
        .toSet()
        .toList();

    availableCapos.sort();

    return availableCapos
        .map((capo) => FilterOption(
              id: capo.toString(),
              displayName: 'Capo $capo'
            ))
        .toList();
  }

  List<FilterOption> _getAvailableTimeSignatures() {
    if (widget.availableSongs == null || widget.availableSongs!.isEmpty) {
      return [];
    }

    final availableTimeSignatures = widget.availableSongs!
        .map((song) => song.timeSignature)
        .where((timeSignature) => timeSignature != null && timeSignature.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    availableTimeSignatures.sort();

    return availableTimeSignatures
        .map((timeSignature) => FilterOption(
              id: timeSignature,
              displayName: timeSignature
            ))
        .toList();
  }

  String _formatDifficultyName(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return 'Beginner';
      case 'EASY':
        return 'Easy';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      case 'EXPERT':
        return 'Expert';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clean minimal header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDialogTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_getActiveFilterCount() > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${_getActiveFilterCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.grey[800],
            ),

            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildFilterContent(),
              ),
            ),

            // Clean action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  // Clear button (only show if filters are active)
                  if (_getActiveFilterCount() > 0) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: _resetFilters,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Apply button
                  Expanded(
                    flex: _getActiveFilterCount() > 0 ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    switch (widget.tabIndex) {
      case 0:
        return _buildSongFilters();
      case 1:
        return _buildArtistFilters();
      case 2:
        return _buildCollectionFilters();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSongFilters() {
    // Get dynamic filter options
    final availableKeys = _getAvailableKeys();
    final availableDifficulties = _getAvailableDifficulties();
    final availableCapos = _getAvailableCapos();
    final availableTimeSignatures = _getAvailableTimeSignatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort by
        _buildFilterSection(
          'Sort by',
          _buildSortOptions(
            options: FilterOptions.songSortOptions,
            selectedOption: _songFilters.sortBy,
            onSelected: (value) {
              setState(() {
                _songFilters.sortBy = value;
              });
            },
          ),
        ),

        // Difficulty filter
        if (availableDifficulties.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFilterSection(
            'Difficulty',
            _buildFilterOptions(
              options: availableDifficulties,
              selectedOption: _songFilters.difficulty,
              onSelected: (value) {
                setState(() {
                  _songFilters.difficulty = value;
                });
              },
            ),
          ),
        ],

        // Key filter
        if (availableKeys.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFilterSection(
            'Key',
            _buildFilterOptions(
              options: availableKeys,
              selectedOption: _songFilters.key,
              onSelected: (value) {
                setState(() {
                  _songFilters.key = value;
                });
              },
            ),
          ),
        ],

        // Capo filter
        if (availableCapos.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFilterSection(
            'Capo',
            _buildFilterOptions(
              options: availableCapos,
              selectedOption: _songFilters.capo?.toString(),
              onSelected: (value) {
                setState(() {
                  _songFilters.capo = value != null ? int.parse(value) : null;
                });
              },
            ),
          ),
        ],

        // Time Signature filter
        if (availableTimeSignatures.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFilterSection(
            'Time Signature',
            _buildFilterOptions(
              options: availableTimeSignatures,
              selectedOption: _songFilters.timeSignature,
              onSelected: (value) {
                setState(() {
                  _songFilters.timeSignature = value;
                });
              },
            ),
          ),
        ],

        // Show message if no filters are available
        if (availableKeys.isEmpty &&
            availableDifficulties.isEmpty &&
            availableCapos.isEmpty &&
            availableTimeSignatures.isEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Search for songs to see available filters',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArtistFilters() {
    return _buildFilterSection(
      'Sort by',
      _buildSortOptions(
        options: FilterOptions.artistSortOptions,
        selectedOption: _artistFilters.sortBy,
        onSelected: (value) {
          setState(() {
            _artistFilters.sortBy = value;
          });
        },
      ),
    );
  }

  Widget _buildCollectionFilters() {
    return _buildFilterSection(
      'Sort by',
      _buildSortOptions(
        options: FilterOptions.collectionSortOptions,
        selectedOption: _collectionFilters.sortBy,
        onSelected: (value) {
          setState(() {
            _collectionFilters.sortBy = value;
          });
        },
      ),
    );
  }



  Widget _buildSortOptions({
    required List<FilterOption> options,
    required String? selectedOption,
    required Function(String?) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.id == selectedOption;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : option.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.grey[800],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              option.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterOptions({
    required List<FilterOption> options,
    required String? selectedOption,
    required Function(String?) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.id == selectedOption;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : option.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.grey[800],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              option.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _resetFilters() {
    setState(() {
      switch (widget.tabIndex) {
        case 0:
          _songFilters = SongSearchFilters();
          break;
        case 1:
          _artistFilters = ArtistSearchFilters();
          break;
        case 2:
          _collectionFilters = CollectionSearchFilters();
          break;
      }
    });
  }

  void _applyFilters() {
    switch (widget.tabIndex) {
      case 0:
        widget.onSongFiltersApplied(_songFilters);
        break;
      case 1:
        widget.onArtistFiltersApplied(_artistFilters);
        break;
      case 2:
        widget.onCollectionFiltersApplied(_collectionFilters);
        break;
    }
    Navigator.of(context).pop();
  }

  // Helper method to get dialog title based on current tab
  String _getDialogTitle() {
    switch (widget.tabIndex) {
      case 0:
        return 'Song Filters';
      case 1:
        return 'Artist Filters';
      case 2:
        return 'Collection Filters';
      default:
        return 'Filters';
    }
  }

  // Helper method to count active filters
  int _getActiveFilterCount() {
    switch (widget.tabIndex) {
      case 0:
        int count = 0;
        if (_songFilters.sortBy != null) count++;
        if (_songFilters.difficulty != null) count++;
        if (_songFilters.key != null) count++;
        if (_songFilters.capo != null) count++;
        if (_songFilters.timeSignature != null) count++;
        if (_songFilters.artistId != null) count++;
        if (_songFilters.languageId != null) count++;
        if (_songFilters.tags.isNotEmpty) count++;
        return count;
      case 1:
        return _artistFilters.sortBy != null ? 1 : 0;
      case 2:
        return _collectionFilters.sortBy != null ? 1 : 0;
      default:
        return 0;
    }
  }

  // Clean minimal filter section builder
  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
