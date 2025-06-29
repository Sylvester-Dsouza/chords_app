import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../core/service_locator.dart';
import '../config/theme.dart';

/// Widget that shows connectivity status and provides helpful messages
class ConnectivityStatusWidget extends StatefulWidget {
  final bool showWhenOnline;
  final EdgeInsets? margin;
  final VoidCallback? onRetryPressed;
  final bool showRetryButton;

  const ConnectivityStatusWidget({
    super.key,
    this.showWhenOnline = false,
    this.margin,
    this.onRetryPressed,
    this.showRetryButton = true,
  });

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = serviceLocator.connectivityService;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _connectivityService,
      child: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          // Don't show anything if online and showWhenOnline is false
          if (connectivityService.isFullyOnline && !widget.showWhenOnline) {
            return const SizedBox.shrink();
          }

          // Don't show if margin is zero (indicates parent doesn't want to show it)
          final margin = widget.margin ?? const EdgeInsets.all(8.0);
          if (margin == EdgeInsets.zero) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: margin,
            child: _buildStatusWidget(connectivityService),
          );
        },
      ),
    );
  }

  Widget _buildStatusWidget(ConnectivityService connectivityService) {
    if (connectivityService.isFullyOnline) {
      return _buildOnlineWidget();
    }

    final issueType = connectivityService.getConnectivityIssueType();
    switch (issueType) {
      case ConnectivityIssueType.noNetwork:
        return _buildNoNetworkWidget(connectivityService);
      case ConnectivityIssueType.noInternet:
        return _buildNoInternetWidget(connectivityService);
      case ConnectivityIssueType.apiUnreachable:
        return _buildApiUnreachableWidget(connectivityService);
      default:
        return _buildOnlineWidget();
    }
  }

  Widget _buildOnlineWidget() {
    if (!widget.showWhenOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected and online',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNetworkWidget(ConnectivityService connectivityService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Network Connection',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your WiFi or mobile data connection and try again.',
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          if (widget.showRetryButton) ...[
            const SizedBox(height: 12),
            _buildRetryButton(connectivityService),
          ],
        ],
      ),
    );
  }

  Widget _buildNoInternetWidget(ConnectivityService connectivityService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.signal_wifi_connected_no_internet_4,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Internet Access',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connected to network but no internet access. Please check your connection settings.',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          if (widget.showRetryButton) ...[
            const SizedBox(height: 12),
            _buildRetryButton(connectivityService),
          ],
        ],
      ),
    );
  }

  Widget _buildApiUnreachableWidget(ConnectivityService connectivityService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Server Unreachable',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Internet is available but our servers are unreachable. This may be temporary.',
            style: TextStyle(
              color: Colors.amber.shade700.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          if (widget.showRetryButton) ...[
            const SizedBox(height: 12),
            _buildRetryButton(connectivityService),
          ],
        ],
      ),
    );
  }

  Widget _buildRetryButton(ConnectivityService connectivityService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Refresh connectivity status
          await connectivityService.refreshConnectivity();
          
          // Call custom retry callback if provided
          if (widget.onRetryPressed != null) {
            widget.onRetryPressed!();
          }
        },
        icon: Icon(Icons.refresh, size: 18),
        label: Text('Retry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

/// Compact connectivity indicator for app bars or status areas
class ConnectivityIndicator extends StatefulWidget {
  final EdgeInsets? margin;

  const ConnectivityIndicator({
    super.key,
    this.margin,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = serviceLocator.connectivityService;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _connectivityService,
      child: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          if (connectivityService.isFullyOnline) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: widget.margin ?? const EdgeInsets.all(4.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getIndicatorColor(connectivityService).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIndicatorIcon(connectivityService),
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getIndicatorText(connectivityService),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getIndicatorColor(ConnectivityService connectivityService) {
    final issueType = connectivityService.getConnectivityIssueType();
    switch (issueType) {
      case ConnectivityIssueType.noNetwork:
        return Colors.red;
      case ConnectivityIssueType.noInternet:
        return Colors.orange;
      case ConnectivityIssueType.apiUnreachable:
        return Colors.amber.shade700;
      default:
        return Colors.green;
    }
  }

  IconData _getIndicatorIcon(ConnectivityService connectivityService) {
    final issueType = connectivityService.getConnectivityIssueType();
    switch (issueType) {
      case ConnectivityIssueType.noNetwork:
        return Icons.wifi_off;
      case ConnectivityIssueType.noInternet:
        return Icons.signal_wifi_connected_no_internet_4;
      case ConnectivityIssueType.apiUnreachable:
        return Icons.cloud_off;
      default:
        return Icons.wifi;
    }
  }

  String _getIndicatorText(ConnectivityService connectivityService) {
    final issueType = connectivityService.getConnectivityIssueType();
    switch (issueType) {
      case ConnectivityIssueType.noNetwork:
        return 'No Network';
      case ConnectivityIssueType.noInternet:
        return 'No Internet';
      case ConnectivityIssueType.apiUnreachable:
        return 'Server Issue';
      default:
        return 'Online';
    }
  }
}
