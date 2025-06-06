import 'package:flutter/material.dart';
import '../services/offline_service.dart';

/// Widget that shows offline status indicator
class OfflineIndicator extends StatefulWidget {
  final bool showWhenOnline;
  final EdgeInsets? margin;

  const OfflineIndicator({
    super.key,
    this.showWhenOnline = false,
    this.margin,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final OfflineService _offlineService = OfflineService();
  bool _isOnline = true;
  bool _offlineModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();

    // Listen for connectivity changes
    _startListening();
  }

  void _startListening() {
    // Check status periodically
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateStatus();
        _startListening();
      }
    });
  }

  void _updateStatus() {
    if (mounted) {
      setState(() {
        _isOnline = _offlineService.isOnline;
        _offlineModeEnabled = _offlineService.offlineModeEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if online and showWhenOnline is false
    if (_isOnline && !_offlineModeEnabled && !widget.showWhenOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      child: _buildIndicator(),
    );
  }

  Widget _buildIndicator() {
    if (!_isOnline) {
      return _buildOfflineIndicator();
    } else if (_offlineModeEnabled) {
      return _buildOfflineModeIndicator();
    } else if (widget.showWhenOnline) {
      return _buildOnlineIndicator();
    }

    return const SizedBox.shrink();
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Offline Mode',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner widget that shows offline status at the top of the screen
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final OfflineService _offlineService = OfflineService();
  bool _isOnline = true;
  bool _offlineModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
    _startListening();
  }

  void _startListening() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateStatus();
        _startListening();
      }
    });
  }

  void _updateStatus() {
    if (mounted) {
      setState(() {
        _isOnline = _offlineService.isOnline;
        _offlineModeEnabled = _offlineService.offlineModeEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show banner when offline or in offline mode
        if (!_isOnline || _offlineModeEnabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: !_isOnline ? Colors.red : Colors.orange,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Icon(
                    !_isOnline ? Icons.wifi_off : Icons.cloud_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _offlineService.getOfflineStatusMessage(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_offlineModeEnabled && _isOnline)
                    TextButton(
                      onPressed: () async {
                        await _offlineService.setOfflineModeEnabled(false);
                        _updateStatus();
                      },
                      child: const Text(
                        'Go Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
