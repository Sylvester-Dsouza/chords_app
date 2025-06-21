import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_data_provider.dart';
import '../../services/incremental_sync_service.dart';
import '../../services/image_cache_manager.dart';

/// Debug screen for monitoring cache and sync status
class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({super.key});

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  Map<String, dynamic>? _cacheStats;
  Map<String, dynamic>? _imageCacheStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _isLoading = true);
    
    try {
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
      final cacheStats = await appDataProvider.getCacheStats();
      final imageCacheStats = ImageCacheManager().getCacheStats();
      
      setState(() {
        _cacheStats = cacheStats;
        _imageCacheStats = imageCacheStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cache stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache() async {
    try {
      await IncrementalSyncService().clearAllCache();
      ImageCacheManager().forceCleanup();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All cache cleared successfully')),
      );
      
      await _loadCacheStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache & Sync Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheStats,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllCache,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncStatsCard(),
                  const SizedBox(height: 16),
                  _buildDataStatesCard(),
                  const SizedBox(height: 16),
                  _buildDataCountsCard(),
                  const SizedBox(height: 16),
                  _buildImageCacheCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatsCard() {
    final syncStats = _cacheStats?['sync'] as Map<String, dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incremental Sync Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (syncStats != null) ...[
              _buildStatRow('Online Status', syncStats['isOnline']?.toString() ?? 'Unknown'),
              _buildStatRow('Home Sections Cached', syncStats['homeSections']?.toString() ?? '0'),
              _buildStatRow('Songs Cached', syncStats['songs']?.toString() ?? '0'),
              _buildStatRow('Artists Cached', syncStats['artists']?.toString() ?? '0'),
              _buildStatRow('Collections Cached', syncStats['collections']?.toString() ?? '0'),
              const Divider(),
              _buildStatRow('Last Home Sync', _formatTimestamp(syncStats['lastSyncHomeSections'])),
              _buildStatRow('Last Songs Sync', _formatTimestamp(syncStats['lastSyncSongs'])),
              _buildStatRow('Last Artists Sync', _formatTimestamp(syncStats['lastSyncArtists'])),
              _buildStatRow('Last Collections Sync', _formatTimestamp(syncStats['lastSyncCollections'])),
            ] else
              const Text('No sync stats available'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatesCard() {
    final dataStates = _cacheStats?['dataStates'] as Map<String, dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Loading States',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (dataStates != null) ...[
              ...dataStates.entries.map((entry) => 
                _buildStatRow(entry.key, entry.value.toString().split('.').last)
              ),
            ] else
              const Text('No data states available'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCountsCard() {
    final dataCounts = _cacheStats?['dataCounts'] as Map<String, dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Counts (In Memory)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (dataCounts != null) ...[
              ...dataCounts.entries.map((entry) => 
                _buildStatRow(entry.key, entry.value.toString())
              ),
            ] else
              const Text('No data counts available'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCacheCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Cache Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_imageCacheStats != null) ...[
              _buildStatRow('Current Objects', _imageCacheStats!['currentSize'].toString()),
              _buildStatRow('Max Objects', _imageCacheStats!['maximumSize'].toString()),
              _buildStatRow('Current Size', '${_imageCacheStats!['currentSizeMB'].toStringAsFixed(1)} MB'),
              _buildStatRow('Max Size', '${_imageCacheStats!['maximumSizeMB'].toStringAsFixed(1)} MB'),
              _buildStatRow('Usage', '${((_imageCacheStats!['currentSizeBytes'] / _imageCacheStats!['maximumSizeBytes']) * 100).toStringAsFixed(1)}%'),
            ] else
              const Text('No image cache stats available'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadCacheStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Stats'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllCache,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ImageCacheManager().performCleanup();
                      _loadCacheStats();
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Clean Images'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
                      await appDataProvider.refreshAllData();
                      _loadCacheStats();
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Force Sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Never';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Invalid';
    }
  }
}
