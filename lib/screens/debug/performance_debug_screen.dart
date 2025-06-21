import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_data_provider.dart';
import '../../services/incremental_sync_service.dart';
import '../../services/image_cache_manager.dart';
import '../../services/memory_manager.dart';

/// Comprehensive performance monitoring screen
class PerformanceDebugScreen extends StatefulWidget {
  const PerformanceDebugScreen({super.key});

  @override
  State<PerformanceDebugScreen> createState() => _PerformanceDebugScreenState();
}

class _PerformanceDebugScreenState extends State<PerformanceDebugScreen> {
  Map<String, dynamic>? _performanceStats;
  bool _isLoading = true;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadPerformanceStats();
  }

  Future<void> _loadPerformanceStats() async {
    setState(() => _isLoading = true);

    try {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      final cacheStats = await appDataProvider.getCacheStats();
      final imageCacheStats = ImageCacheManager().getCacheStats();
      final memoryManager = MemoryManager();

      // Get memory status
      String memoryStatus = 'Unknown';
      try {
        memoryStatus = await memoryManager.getMemoryStatus();
      } catch (e) {
        debugPrint('Error getting memory status: $e');
      }

      setState(() {
        _performanceStats = {
          'cache': cacheStats,
          'imageCache': imageCacheStats,
          'memory': memoryStatus,
          'timestamp': DateTime.now(),
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading performance stats: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startMonitoring() {
    setState(() => _isMonitoring = true);

    // Refresh stats every 5 seconds
    Future.doWhile(() async {
      if (!_isMonitoring || !mounted) return false;

      await Future.delayed(const Duration(seconds: 5));
      if (_isMonitoring && mounted) {
        await _loadPerformanceStats();
      }

      return _isMonitoring;
    });
  }

  void _stopMonitoring() {
    setState(() => _isMonitoring = false);
  }

  Future<void> _runPerformanceTest() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running performance test...'),
              ],
            ),
          ),
    );

    try {
      final appDataProvider = Provider.of<AppDataProvider>(
        context,
        listen: false,
      );
      final stopwatch = Stopwatch()..start();

      // Test data loading performance
      await Future.wait([
        appDataProvider.getHomeSections(forceRefresh: true),
        appDataProvider.getSongs(forceRefresh: true),
        appDataProvider.getArtists(forceRefresh: true),
        appDataProvider.getCollections(forceRefresh: true),
      ]);

      stopwatch.stop();

      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Performance Test Results'),
              content: Text(
                'Data loading completed in ${stopwatch.elapsedMilliseconds}ms\n\n'
                'This includes:\n'
                '• Home sections\n'
                '• Songs\n'
                '• Artists\n'
                '• Collections\n\n'
                'All data was loaded from cache or API.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );

      await _loadPerformanceStats();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Performance Test Failed'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceStats,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonitoringCard(),
                    const SizedBox(height: 16),
                    _buildCachePerformanceCard(),
                    const SizedBox(height: 16),
                    _buildMemoryCard(),
                    const SizedBox(height: 16),
                    _buildImageCacheCard(),
                    const SizedBox(height: 16),
                    _buildDataStatesCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMonitoringCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Real-time Monitoring',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isMonitoring ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isMonitoring ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isMonitoring
                  ? 'Monitoring performance metrics every 5 seconds'
                  : 'Tap play button to start real-time monitoring',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_performanceStats != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${_formatTimestamp(_performanceStats!['timestamp'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCachePerformanceCard() {
    final syncStats =
        _performanceStats?['cache']?['sync'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (syncStats != null) ...[
              Row(
                children: [
                  Icon(
                    syncStats['isOnline'] == true ? Icons.wifi : Icons.wifi_off,
                    color:
                        syncStats['isOnline'] == true
                            ? Colors.green
                            : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    syncStats['isOnline'] == true ? 'Online' : 'Offline',
                    style: TextStyle(
                      color:
                          syncStats['isOnline'] == true
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                'Home Sections',
                '${syncStats['homeSections'] ?? 0} cached',
              ),
              _buildStatRow('Songs', '${syncStats['songs'] ?? 0} cached'),
              _buildStatRow('Artists', '${syncStats['artists'] ?? 0} cached'),
              _buildStatRow(
                'Collections',
                '${syncStats['collections'] ?? 0} cached',
              ),
              _buildStatRow('Setlists', '${syncStats['setlists'] ?? 0} cached'),
            ] else
              const Text('No cache stats available'),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard() {
    final memoryStatus = _performanceStats?['memory'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memory Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (memoryStatus != null) ...[
              Text(
                memoryStatus,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ] else
              const Text('Memory status unavailable'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCacheCard() {
    final imageCacheStats =
        _performanceStats?['imageCache'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Cache',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (imageCacheStats != null) ...[
              _buildStatRow(
                'Objects',
                '${imageCacheStats['currentSize']}/${imageCacheStats['maximumSize']}',
              ),
              _buildStatRow(
                'Size',
                '${imageCacheStats['currentSizeMB'].toStringAsFixed(1)}/${imageCacheStats['maximumSizeMB'].toStringAsFixed(1)} MB',
              ),
              _buildStatRow(
                'Usage',
                '${(imageCacheStats['currentSizeBytes'] / imageCacheStats['maximumSizeBytes'] * 100).toStringAsFixed(1)}%',
              ),
            ] else
              const Text('Image cache stats unavailable'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatesCard() {
    final dataStates =
        _performanceStats?['cache']?['dataStates'] as Map<String, dynamic>?;
    final dataCounts =
        _performanceStats?['cache']?['dataCounts'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data States & Counts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (dataStates != null && dataCounts != null) ...[
              ...dataStates.entries.map((entry) {
                final state = entry.value.toString().split('.').last;
                final count = dataCounts[entry.key] ?? 0;
                return _buildStatRow(entry.key, '$count items ($state)');
              }),
            ] else
              const Text('Data states unavailable'),
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
              'Performance Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runPerformanceTest,
                    icon: const Icon(Icons.speed),
                    label: const Text('Run Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      MemoryManager().forceCleanup();
                      _loadPerformanceStats();
                    },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Force Cleanup'),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
