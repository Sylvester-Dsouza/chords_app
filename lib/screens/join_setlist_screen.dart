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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.group_add, size: 48, color: AppTheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Join a Collaborative Setlist',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a 4-digit code or scan a QR code to join',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontFamily: AppTheme.primaryFontFamily,
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
                      color: AppTheme.text,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.primaryFontFamily,
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
                    side: BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _shareCodeController,
              decoration: InputDecoration(
                hintText: 'Enter 4-digit code (e.g., 1234)',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                errorText: _errorMessage,
                prefixIcon: Icon(Icons.code, color: AppTheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: AppTheme.primary.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: AppTheme.primary.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 18,
                letterSpacing: 4,
                fontFamily: AppTheme.monospaceFontFamily,
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
                icon:
                    _isLoading
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                        : const Icon(Icons.preview),
                label: Text(
                  _isLoading ? 'Loading...' : 'Preview Setlist',
                  style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppTheme.primary),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Setlist preview
            if (_previewSetlist != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.queue_music,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
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
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),
                              if (_previewSetlist!.description?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _previewSetlist!.description!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontFamily: AppTheme.primaryFontFamily,
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
                        _buildInfoChip(Icons.person, 'Owner'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Join button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinSetlist,
                        icon:
                            _isJoining
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                : const Icon(Icons.group_add),
                        label: Text(
                          _isJoining ? 'Joining...' : 'Join Setlist',
                          style: TextStyle(
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
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
        color: AppTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.primary.withAlpha(60), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontFamily: AppTheme.primaryFontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
