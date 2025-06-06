import 'package:flutter/material.dart';
import '../services/search_history_service.dart';
import '../config/theme.dart';

/// Widget that displays search suggestions and history
class SearchSuggestionsWidget extends StatelessWidget {
  final String query;
  final SearchType searchType;
  final SearchHistoryService searchHistoryService;
  final Function(String) onSuggestionTap;
  final Function(SearchHistoryItem) onHistoryItemRemove;
  final VoidCallback? onClearHistory;

  const SearchSuggestionsWidget({
    super.key,
    required this.query,
    required this.searchType,
    required this.searchHistoryService,
    required this.onSuggestionTap,
    required this.onHistoryItemRemove,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (!searchHistoryService.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final suggestions = searchHistoryService.getSuggestions(query, type: searchType);
    final recentHistory = searchHistoryService.getHistoryByType(searchType).take(5).toList();

    if (suggestions.isEmpty && recentHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions section
          if (suggestions.isNotEmpty) ...[
            _buildSectionHeader(
              query.isEmpty ? 'Recent Searches' : 'Suggestions',
              Icons.search,
            ),
            ...suggestions.map((suggestion) => _buildSuggestionItem(suggestion)),
          ],

          // History section (only show if query is empty and we have history)
          if (query.isEmpty && recentHistory.isNotEmpty) ...[
            if (suggestions.isNotEmpty) const Divider(color: Color(0xFF333333), height: 1),
            _buildSectionHeader(
              'Search History',
              Icons.history,
              showClearButton: true,
            ),
            ...recentHistory.map((item) => _buildHistoryItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            'No search history yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start searching to see suggestions and history',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool showClearButton = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (showClearButton && onClearHistory != null)
            GestureDetector(
              onTap: onClearHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return InkWell(
      onTap: () => onSuggestionTap(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.north_west,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(SearchHistoryItem item) {
    return InkWell(
      onTap: () => onSuggestionTap(item.query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 18,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.query,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onHistoryItemRemove(item),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Overlay widget for showing search suggestions
class SearchSuggestionsOverlay extends StatelessWidget {
  final Widget child;
  final bool showSuggestions;
  final String query;
  final SearchType searchType;
  final SearchHistoryService searchHistoryService;
  final Function(String) onSuggestionTap;
  final Function(SearchHistoryItem) onHistoryItemRemove;
  final VoidCallback? onClearHistory;

  const SearchSuggestionsOverlay({
    super.key,
    required this.child,
    required this.showSuggestions,
    required this.query,
    required this.searchType,
    required this.searchHistoryService,
    required this.onSuggestionTap,
    required this.onHistoryItemRemove,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showSuggestions)
          Positioned(
            top: 60, // Adjust based on search bar height
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: SearchSuggestionsWidget(
                query: query,
                searchType: searchType,
                searchHistoryService: searchHistoryService,
                onSuggestionTap: onSuggestionTap,
                onHistoryItemRemove: onHistoryItemRemove,
                onClearHistory: onClearHistory,
              ),
            ),
          ),
      ],
    );
  }
}
