import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';
import '../utils/ui_helpers.dart';
import '../widgets/inner_screen_app_bar.dart';

/// Screen for joining a setlist via share code or link
class JoinSetlistScreen extends StatefulWidget {
  final String? shareCode;

  const JoinSetlistScreen({
    super.key,
    this.shareCode,
  });

  @override
  State<JoinSetlistScreen> createState() => _JoinSetlistScreenState();
}

class _JoinSetlistScreenState extends State<JoinSetlistScreen> {
  final TextEditingController _shareCodeController = TextEditingController();
  final SetlistService _setlistService = SetlistService();

  bool _isLoading = false;
  bool _isJoining = false;
  String? _errorMessage;
  Setlist? _previewSetlist;

  @override
  void initState() {
    super.initState();
    if (widget.shareCode != null) {
      _shareCodeController.text = widget.shareCode!;
      _previewSetlistData();
    }
  }

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  // Preview setlist before joining
  Future<void> _previewSetlistData() async {
    final shareCode = _shareCodeController.text.trim();
    if (shareCode.isEmpty) {
      setState(() {
        _previewSetlist = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final setlist = await _setlistService.getSetlistByShareCode(shareCode);

      if (mounted) {
        setState(() {
          _previewSetlist = setlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewSetlist = null;
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // Join the setlist
  Future<void> _joinSetlist() async {
    if (_previewSetlist == null) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await _setlistService.joinSetlist(_previewSetlist!.shareCode!);

      if (mounted) {
        UIHelpers.showSuccessSnackBar(
          context,
          'Successfully joined "${_previewSetlist!.name}"',
        );

        // Return to setlists screen with refresh signal
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Join Setlist',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC19FFF).withValues(alpha: 0.1),
                    const Color(0xFFC19FFF).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC19FFF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.group_add,
                    size: 48,
                    color: const Color(0xFFC19FFF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join a Collaborative Setlist',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a 4-digit code or scan a QR code to join',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share code input with QR scanner
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share Code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final result = await navigator.pushNamed('/qr-scanner');
                    if (result == true && mounted) {
                      // QR scanner successfully joined a setlist, navigate back to setlists
                      navigator.pop(true); // Return to setlists with refresh signal
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC19FFF)),
                    foregroundColor: const Color(0xFFC19FFF),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _shareCodeController,
              decoration: InputDecoration(
                hintText: 'Enter 4-digit code (e.g., 1234)',
                errorText: _errorMessage,
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (value) {
                // Auto-preview when user types 4 digits
                if (value.length == 4) {
                  _previewSetlistData();
                } else {
                  setState(() {
                    _previewSetlist = null;
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _previewSetlistData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.preview),
                label: Text(_isLoading ? 'Loading...' : 'Preview Setlist'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: const Color(0xFFC19FFF)),
                  foregroundColor: const Color(0xFFC19FFF),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Setlist preview
            if (_previewSetlist != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC19FFF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.queue_music,
                          color: const Color(0xFFC19FFF),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewSetlist!.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_previewSetlist!.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _previewSetlist!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Setlist info
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.music_note,
                          '${_previewSetlist!.songs?.length ?? 0} songs',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.person,
                          'Owner',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Join button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinSetlist,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.group_add),
                        label: Text(_isJoining ? 'Joining...' : 'Join Setlist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC19FFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
