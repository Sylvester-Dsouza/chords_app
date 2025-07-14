import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';
import '../utils/ui_helpers.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../config/theme.dart';

/// Screen for joining a setlist via share code or link
class JoinSetlistScreen extends StatefulWidget {
  final String? shareCode;

  const JoinSetlistScreen({super.key, this.shareCode});

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
      backgroundColor: AppTheme.background,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.border,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.group_add,
                      size: 32,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join a Collaborative Setlist',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 4-digit share code from your team leader',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ask your team leader for the share code',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Share code input with QR scanner
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share Code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
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
                      navigator.pop(
                        true,
                      ); // Return to setlists with refresh signal
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border, width: 1.5),
                    foregroundColor: AppTheme.textSecondary,
                    backgroundColor: AppTheme.surfaceSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _shareCodeController,
                decoration: InputDecoration(
                  hintText: '1234',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                    fontSize: 20,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                  errorText: _errorMessage,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.vpn_key,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.border,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 20,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w600,
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
            ),
            const SizedBox(height: 20),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _previewSetlistData,
                icon:
                    _isLoading
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                        : const Icon(Icons.preview, size: 20),
                label: Text(
                  _isLoading ? 'Loading...' : 'Preview Setlist',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.border, width: 1.5),
                  foregroundColor: AppTheme.textSecondary,
                  backgroundColor: AppTheme.surfaceSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Setlist preview
            if (_previewSetlist != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.queue_music,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewSetlist!.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_previewSetlist!.description?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _previewSetlist!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Setlist info
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.music_note,
                          '${_previewSetlist!.songs?.length ?? 0} songs',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(Icons.person, 'Owner'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Join button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinSetlist,
                        icon:
                            _isJoining
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                : const Icon(Icons.group_add, size: 20),
                        label: Text(
                          _isJoining ? 'Joining...' : 'Join Setlist',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
