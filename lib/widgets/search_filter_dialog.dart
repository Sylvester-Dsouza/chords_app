import 'package:flutter/material.dart';
import '../models/search_filters.dart';

class SearchFilterDialog extends StatefulWidget {
  final int tabIndex; // 0 = Songs, 1 = Artists, 2 = Collections
  final SongSearchFilters? songFilters;
  final ArtistSearchFilters? artistFilters;
  final CollectionSearchFilters? collectionFilters;
  final Function(SongSearchFilters) onSongFiltersApplied;
  final Function(ArtistSearchFilters) onArtistFiltersApplied;
  final Function(CollectionSearchFilters) onCollectionFiltersApplied;

  const SearchFilterDialog({
    super.key,
    required this.tabIndex,
    this.songFilters,
    this.artistFilters,
    this.collectionFilters,
    required this.onSongFiltersApplied,
    required this.onArtistFiltersApplied,
    required this.onCollectionFiltersApplied,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter content based on tab
            Flexible(
              child: SingleChildScrollView(
                child: _buildFilterContent(),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reset button
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Apply button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC19FFF), // Light purple/lavender
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort by
        _buildSectionTitle('Sort by'),
        _buildSortOptions(
          options: FilterOptions.songSortOptions,
          selectedOption: _songFilters.sortBy,
          onSelected: (value) {
            setState(() {
              _songFilters.sortBy = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Difficulty
        _buildSectionTitle('Difficulty'),
        _buildFilterOptions(
          options: FilterOptions.difficulties,
          selectedOption: _songFilters.difficulty,
          onSelected: (value) {
            setState(() {
              _songFilters.difficulty = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Key
        _buildSectionTitle('Key'),
        _buildFilterOptions(
          options: FilterOptions.keys,
          selectedOption: _songFilters.key,
          onSelected: (value) {
            setState(() {
              _songFilters.key = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Capo
        _buildSectionTitle('Capo'),
        _buildFilterOptions(
          options: FilterOptions.capos,
          selectedOption: _songFilters.capo?.toString(),
          onSelected: (value) {
            setState(() {
              _songFilters.capo = value != null ? int.parse(value) : null;
            });
          },
        ),
        const SizedBox(height: 16),

        // Time Signature
        _buildSectionTitle('Time Signature'),
        _buildFilterOptions(
          options: FilterOptions.timeSignatures,
          selectedOption: _songFilters.timeSignature,
          onSelected: (value) {
            setState(() {
              _songFilters.timeSignature = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildArtistFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort by
        _buildSectionTitle('Sort by'),
        _buildSortOptions(
          options: FilterOptions.artistSortOptions,
          selectedOption: _artistFilters.sortBy,
          onSelected: (value) {
            setState(() {
              _artistFilters.sortBy = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCollectionFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort by
        _buildSectionTitle('Sort by'),
        _buildSortOptions(
          options: FilterOptions.collectionSortOptions,
          selectedOption: _collectionFilters.sortBy,
          onSelected: (value) {
            setState(() {
              _collectionFilters.sortBy = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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
        return ChoiceChip(
          label: Text(option.displayName),
          selected: isSelected,
          selectedColor: const Color(0xFFC19FFF), // Light purple/lavender
          backgroundColor: const Color(0xFF333333),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
          ),
          onSelected: (selected) {
            onSelected(selected ? option.id : null);
          },
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
        return FilterChip(
          label: Text(option.displayName),
          selected: isSelected,
          selectedColor: const Color(0xFFC19FFF), // Light purple/lavender
          backgroundColor: const Color(0xFF333333),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
          ),
          onSelected: (selected) {
            onSelected(selected ? option.id : null);
          },
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
}
