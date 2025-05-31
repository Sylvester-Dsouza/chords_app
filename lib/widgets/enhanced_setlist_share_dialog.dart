import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';
import '../utils/ui_helpers.dart';

/// Enhanced share dialog with QR code and multiple sharing options
class EnhancedSetlistShareDialog extends StatefulWidget {
  final Setlist setlist;
  final Function onSetlistUpdated;

  const EnhancedSetlistShareDialog({
    super.key,
    required this.setlist,
    required this.onSetlistUpdated,
  });

  @override
  State<EnhancedSetlistShareDialog> createState() => _EnhancedSetlistShareDialogState();
}

class _EnhancedSetlistShareDialogState extends State<EnhancedSetlistShareDialog> {
  final SetlistService _setlistService = SetlistService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _shareCode;
  String? _deepLink;
  bool _useDeepLink = true; // Toggle between deep link and simple code

  @override
  void initState() {
    super.initState();
    _generateShareCode();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Generate 4-digit share code and deep link
  Future<void> _generateShareCode() async {
    if (widget.setlist.shareCode != null) {
      setState(() {
        _shareCode = widget.setlist.shareCode;
        _deepLink = 'stuthi://join/${widget.setlist.shareCode}';
      });

      // Auto-copy code when dialog opens
      _copyShareCode();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Enable sharing to generate share code
      await _setlistService.updateSetlistSettings(
        widget.setlist.id,
        isPublic: false,
        allowEditing: widget.setlist.allowEditing,
        allowComments: widget.setlist.allowComments,
      );

      // Reload setlist data to get the share code
      final updatedSetlist = await _setlistService.getSetlistById(widget.setlist.id);

      if (mounted) {
        setState(() {
          _shareCode = updatedSetlist.shareCode;
          _deepLink = 'stuthi://join/${updatedSetlist.shareCode}';
          _isLoading = false;
        });

        // Auto-copy the generated code
        _copyShareCode();

        // Show success message
        UIHelpers.showSuccessSnackBar(
          context,
          'Share code generated and copied!',
        );

        // Update parent
        widget.onSetlistUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // Copy share code to clipboard
  Future<void> _copyShareCode() async {
    if (_shareCode != null) {
      await Clipboard.setData(ClipboardData(text: _shareCode!));
      if (mounted) {
        UIHelpers.showSuccessSnackBar(
          context,
          'Share code copied to clipboard',
        );
      }
    }
  }

  // Share via native sharing
  Future<void> _shareViaSystem() async {
    if (_shareCode == null || _deepLink == null) return;

    final shareText = '''🎵 Join "${widget.setlist.name}" setlist on Stuthi!

Quick join: $_deepLink
Or enter code: $_shareCode

Download Stuthi app to join the collaborative setlist.''';

    try {
      await Share.share(
        shareText,
        subject: 'Join my setlist on Stuthi',
      );
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context,
          'Failed to share: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share "${widget.setlist.name}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content based on state
            if (_isLoading) ...[
              const CircularProgressIndicator(
                color: Color(0xFFC19FFF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generating share code...',
                style: TextStyle(color: Colors.white),
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _generateShareCode,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC19FFF)),
                  foregroundColor: const Color(0xFFC19FFF),
                ),
                child: const Text('Try Again'),
              ),
            ] else if (_shareCode != null && _deepLink != null) ...[
              // QR Code and sharing options
              _buildSharingContent(),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharingContent() {
    return Column(
      children: [
        // QR Code section - Compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // QR Code
              QrImageView(
                data: _useDeepLink ? _deepLink! : _shareCode!,
                version: QrVersions.auto,
                size: 140.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
              const SizedBox(height: 8),

              // QR Type Toggle - Minimal
              ToggleButtons(
                isSelected: [_useDeepLink, !_useDeepLink],
                onPressed: (index) {
                  setState(() {
                    _useDeepLink = index == 0;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                constraints: const BoxConstraints(minWidth: 50, minHeight: 28),
                textStyle: const TextStyle(fontSize: 11),
                selectedColor: Colors.white,
                fillColor: const Color(0xFFC19FFF),
                color: Colors.grey[600],
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Link'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Code'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Share code display - Compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Join Code',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Large share code display
              Text(
                _shareCode!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons - Compact
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyShareCode,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC19FFF)),
                  foregroundColor: const Color(0xFFC19FFF),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareViaSystem,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC19FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Instructions - Minimal
        Text(
          'Scan QR or share the 4-digit code',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
