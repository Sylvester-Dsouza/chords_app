import 'package:flutter/material.dart';
import '../services/setlist_service.dart';
import '../models/setlist.dart';
import '../utils/ui_helpers.dart';

class SetlistSettingsDialog extends StatefulWidget {
  final Setlist setlist;
  final Function onSetlistUpdated;

  const SetlistSettingsDialog({
    super.key,
    required this.setlist,
    required this.onSetlistUpdated,
  });

  @override
  State<SetlistSettingsDialog> createState() => _SetlistSettingsDialogState();
}

class _SetlistSettingsDialogState extends State<SetlistSettingsDialog> {
  final SetlistService _setlistService = SetlistService();
  bool _isLoading = false;

  // Settings
  late bool _isPublic;
  late bool _allowEditing;
  late bool _allowComments;
  bool _isOfflineAvailable = false; // Initialize with default value

  @override
  void initState() {
    super.initState();
    _isPublic = widget.setlist.isPublic;
    _allowEditing = widget.setlist.allowEditing;
    _allowComments = widget.setlist.allowComments;

    // Check if setlist is available offline
    _checkOfflineAvailability();
  }

  Future<void> _checkOfflineAvailability() async {
    try {
      final offlineSetlist = await _setlistService.getOfflineSetlist(widget.setlist.id);
      if (mounted) {
        setState(() {
          _isOfflineAvailable = offlineSetlist != null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOfflineAvailable = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final settings = {
        'isPublic': _isPublic,
        'allowEditing': _allowEditing,
        'allowComments': _allowComments,
      };

      final updatedSetlist = await _setlistService.updateSettings(
        widget.setlist.id,
        settings,
      );

      // Update offline if enabled
      if (_isOfflineAvailable) {
        await _setlistService.saveSetlistOffline(updatedSetlist);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        UIHelpers.showSuccessSnackBar(
          context,
          'Settings saved successfully',
        );

        // Update parent
        widget.onSetlistUpdated();

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        UIHelpers.showErrorSnackBar(
          context,
          'Failed to save settings: $e',
        );
      }
    }
  }

  Future<void> _toggleOfflineAvailability() async {
    try {
      if (_isOfflineAvailable) {
        // Remove from offline storage
        await _setlistService.deleteOfflineSetlist(widget.setlist.id);

        if (mounted) {
          setState(() {
            _isOfflineAvailable = false;
          });

          UIHelpers.showSuccessSnackBar(
            context,
            'Setlist removed from offline storage',
          );
        }
      } else {
        // Save for offline use
        await _setlistService.saveSetlistOffline(widget.setlist);

        if (mounted) {
          setState(() {
            _isOfflineAvailable = true;
          });

          UIHelpers.showSuccessSnackBar(
            context,
            'Setlist saved for offline use',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context,
          'Failed to update offline availability: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Setlist Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Collaboration settings
            Text(
              'Collaboration Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Public Setlist'),
              subtitle: const Text('Anyone with the link can view this setlist'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Allow Editing'),
              subtitle: const Text('Collaborators can edit this setlist'),
              value: _allowEditing,
              onChanged: (value) {
                setState(() {
                  _allowEditing = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Allow Comments'),
              subtitle: const Text('Collaborators can comment on this setlist'),
              value: _allowComments,
              onChanged: (value) {
                setState(() {
                  _allowComments = value;
                });
              },
            ),

            const Divider(),

            // Offline settings
            Text(
              'Offline Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Available Offline'),
              subtitle: const Text('Save this setlist for offline use'),
              value: _isOfflineAvailable,
              onChanged: (value) {
                _toggleOfflineAvailability();
              },
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
