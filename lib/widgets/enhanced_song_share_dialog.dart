import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import '../utils/ui_helpers.dart';

/// Enhanced share dialog for songs with QR code and multiple sharing options
class EnhancedSongShareDialog extends StatefulWidget {
  final Song song;

  const EnhancedSongShareDialog({
    super.key,
    required this.song,
  });

  @override
  State<EnhancedSongShareDialog> createState() => _EnhancedSongShareDialogState();
}

class _EnhancedSongShareDialogState extends State<EnhancedSongShareDialog> {
  String? _deepLink;
  bool _useDeepLink = true; // Toggle between deep link and song ID

  @override
  void initState() {
    super.initState();
    _generateDeepLink();
  }

  void _generateDeepLink() {
    setState(() {
      _deepLink = 'stuthi://song/${widget.song.id}';
    });

    // Auto-copy the song ID when dialog opens
    _copySongId();
  }

  // Copy song ID to clipboard
  Future<void> _copySongId() async {
    await Clipboard.setData(ClipboardData(text: widget.song.id));
    if (mounted) {
      UIHelpers.showSuccessSnackBar(
        context,
        'Song ID copied to clipboard',
      );
    }
  }

  // Share via native sharing
  Future<void> _shareViaSystem() async {
    if (_deepLink == null) return;

    final shareText = '''🎵 Check out "${widget.song.title}" by ${widget.song.artist} on Stuthi!

Quick open: $_deepLink
Or search for: ${widget.song.title}

Download Stuthi app for worship song chords and lyrics.''';

    try {
      await Share.share(
        shareText,
        subject: 'Song: ${widget.song.title} - Stuthi',
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
                      'Share "${widget.song.title}"',
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

              // Song info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${widget.song.artist}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    if (widget.song.key.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Key: ${widget.song.key}',
                        style: TextStyle(
                          color: const Color(0xFFC19FFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QR Code and sharing options
              _buildSharingContent(),
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
                data: _useDeepLink ? _deepLink! : widget.song.id,
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
                    child: Text('ID'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Song ID display - Compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Song ID',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Song ID display
              Text(
                widget.song.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
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
                onPressed: _copySongId,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy ID'),
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
          'Scan QR or share the song details',
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
