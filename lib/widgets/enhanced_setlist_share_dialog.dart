import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';
import '../services/community_service.dart';
import '../utils/ui_helpers.dart';
import '../core/service_locator.dart';
import '../config/theme.dart';

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
  late final CommunityService _communityService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _shareCode;
  String? _deepLink;
  bool _useDeepLink = true; // Toggle between deep link and simple code
  bool _isPublic = false;
  bool _isTogglingPublic = false;

  @override
  void initState() {
    super.initState();
    _communityService = serviceLocator<CommunityService>();
    _isPublic = widget.setlist.isPublic;
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

  // Toggle public/private status
  Future<void> _togglePublicStatus() async {
    if (_isTogglingPublic) return;

    setState(() {
      _isTogglingPublic = true;
    });

    try {
      if (_isPublic) {
        await _communityService.makeSetlistPrivate(widget.setlist.id);
        setState(() {
          _isPublic = false;
        });
        if (mounted) {
          UIHelpers.showSuccessSnackBar(
            context,
            'Setlist removed from community',
          );
        }
      } else {
        await _communityService.makeSetlistPublic(widget.setlist.id);
        setState(() {
          _isPublic = true;
        });
        if (mounted) {
          UIHelpers.showSuccessSnackBar(
            context,
            'Setlist shared with community!',
          );
        }
      }

      // Notify parent to refresh
      widget.onSetlistUpdated();
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context,
          'Failed to update setlist: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingPublic = false;
        });
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
                  borderRadius: BorderRadius.circular(5),
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
        // Community sharing section
        _buildCommunitySection(),
        const SizedBox(height: 16),

        // QR Code section - Compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
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
            borderRadius: BorderRadius.circular(5),
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
                  fontFamily: AppTheme.monospaceFontFamily,
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
                    borderRadius: BorderRadius.circular(5),
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
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Clear instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFC19FFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC19FFF).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFFC19FFF), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'How to share this setlist:',
                      style: TextStyle(
                        color: const Color(0xFFC19FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Share the 4-digit code with your team\n2. They open Stuthi app → Setlists → Join\n3. Enter the code to collaborate together',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Community Sharing',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isPublic
                ? 'Your setlist is public and visible to the community'
                : 'Make your setlist public to share with the community',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTogglingPublic ? null : _togglePublicStatus,
              icon: _isTogglingPublic
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isPublic ? Icons.lock : Icons.public),
              label: Text(_isPublic ? 'Make Private' : 'Make Public'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPublic ? AppTheme.textSecondary : AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (_isPublic) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your setlist is now discoverable in the Community tab',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
