import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'setlist_service.dart';
import '../utils/ui_helpers.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  final SetlistService _setlistService = SetlistService();
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;

  /// Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    _context = context;

    // Handle app launch from deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('Received deep link: $uri');

    if (_context == null || !_context!.mounted) {
      debugPrint('Context not available for deep link handling');
      return;
    }

    try {
      // Check if it's a setlist join link
      if (uri.scheme == 'stuthi' && uri.host == 'join') {
        final shareCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

        if (shareCode != null && shareCode.isNotEmpty) {
          await _handleJoinSetlist(shareCode);
        } else {
          _showError('Invalid share code in link');
        }
      }
      // Check if it's a song link
      else if (uri.scheme == 'stuthi' && uri.host == 'song') {
        final songId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

        if (songId != null && songId.isNotEmpty) {
          await _handleOpenSong(songId);
        } else {
          _showError('Invalid song ID in link');
        }
      } else {
        debugPrint('Unhandled deep link: $uri');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      _showError('Failed to process link: $e');
    }
  }

  /// Handle opening a song via song ID
  Future<void> _handleOpenSong(String songId) async {
    if (_context == null || !_context!.mounted) return;

    try {
      // Show loading indicator
      _showLoading('Loading song...');

      // Navigate to song detail screen
      Navigator.of(_context!).pushNamed(
        '/song_detail',
        arguments: {'songId': songId},
      );

      // Hide loading
      _hideLoading();

      if (_context != null && _context!.mounted) {
        UIHelpers.showSuccessSnackBar(
          _context!,
          'Opening song...',
        );
      }
    } catch (e) {
      _hideLoading();
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Handle joining a setlist via share code
  Future<void> _handleJoinSetlist(String shareCode) async {
    if (_context == null || !_context!.mounted) return;

    // Validate share code format
    if (!RegExp(r'^\d{4}$').hasMatch(shareCode)) {
      _showError('Invalid share code format. Expected 4-digit code.');
      return;
    }

    try {
      // Show loading indicator
      _showLoading('Loading setlist...');

      // Get setlist details first
      final setlist = await _setlistService.getSetlistByShareCode(shareCode);

      // Hide loading
      _hideLoading();

      if (_context == null || !_context!.mounted) return;

      // Show confirmation dialog
      final shouldJoin = await _showJoinConfirmationDialog(
        setlist.name,
        'Setlist Owner',
        shareCode,
      );

      if (shouldJoin == true) {
        // Show loading for join operation
        _showLoading('Joining setlist...');

        // Join the setlist
        await _setlistService.joinSetlist(shareCode);

        // Hide loading
        _hideLoading();

        if (_context != null && _context!.mounted) {
          UIHelpers.showSuccessSnackBar(
            _context!,
            'Successfully joined "${setlist.name}"!',
          );

          // Navigate to setlists screen
          Navigator.of(_context!).pushNamedAndRemoveUntil(
            '/setlist',
            (route) => false,
          );
        }
      }
    } catch (e) {
      _hideLoading();
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Show join confirmation dialog
  Future<bool?> _showJoinConfirmationDialog(String setlistName, String ownerName, String shareCode) {
    if (_context == null || !_context!.mounted) return Future.value(false);

    return showDialog<bool>(
      context: _context!,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.queue_music,
              color: const Color(0xFFC19FFF),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Join Setlist',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to join this setlist?',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setlistName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by: $ownerName',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: $shareCode',
                    style: TextStyle(
                      color: const Color(0xFFC19FFF),
                      fontSize: 14,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC19FFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  void _showLoading(String message) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Row(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFC19FFF),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  void _hideLoading() {
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pop();
    }
  }

  /// Show error message
  void _showError(String message) {
    if (_context != null && _context!.mounted) {
      UIHelpers.showErrorSnackBar(_context!, message);
    }
  }

  /// Create a deep link for joining a setlist
  static String createJoinLink(String shareCode) {
    return 'stuthi://join/$shareCode';
  }

  /// Create a deep link for opening a song
  static String createSongLink(String songId) {
    return 'stuthi://song/$songId';
  }

  /// Validate if a string is a valid deep link
  static bool isValidDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme != 'stuthi' || uri.pathSegments.isEmpty) {
        return false;
      }

      // Validate setlist join links
      if (uri.host == 'join') {
        return RegExp(r'^\d{4}$').hasMatch(uri.pathSegments.first);
      }

      // Validate song links
      if (uri.host == 'song') {
        return uri.pathSegments.first.isNotEmpty;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract share code from deep link
  static String? extractShareCode(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme == 'stuthi' && uri.host == 'join' && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    } catch (e) {
      debugPrint('Error extracting share code: $e');
    }
    return null;
  }

  /// Extract song ID from deep link
  static String? extractSongId(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme == 'stuthi' && uri.host == 'song' && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    } catch (e) {
      debugPrint('Error extracting song ID: $e');
    }
    return null;
  }
}
