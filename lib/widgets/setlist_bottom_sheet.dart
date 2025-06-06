import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';
import '../config/theme.dart';

class SetlistBottomSheet extends StatefulWidget {
  final Song song;

  const SetlistBottomSheet({super.key, required this.song});

  @override
  State<SetlistBottomSheet> createState() => _SetlistBottomSheetState();
}

class _SetlistBottomSheetState extends State<SetlistBottomSheet> {
  final TextEditingController _newSetlistController = TextEditingController();
  bool _isCreatingNewSetlist = false;
  bool _isLoading = true;
  bool _isCreatingSetlist = false;
  bool _isSavingSelections = false;
  String? _errorMessage;

  // Setlist service
  final SetlistService _setlistService = SetlistService();

  // Setlists data
  List<Setlist> _setlists = [];

  // Map to track which setlists contain the song
  Map<String, bool> _setlistContainsSong = {};

  @override
  void initState() {
    super.initState();
    _fetchSetlists();
  }

  // Fetch setlists from the API and check which ones contain the song
  Future<void> _fetchSetlists() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get all setlists
      final setlists = await _setlistService.getSetlists();

      // Initialize the map to track which setlists contain the song
      final Map<String, bool> setlistContainsSong = {};

      // Check each setlist to see if it contains the song
      for (final setlist in setlists) {
        try {
          final containsSong = await _setlistService.isSongInSetlist(setlist.id, widget.song.id);
          setlistContainsSong[setlist.id] = containsSong;
        } catch (e) {
          debugPrint('Error checking if setlist ${setlist.id} contains song: $e');
          setlistContainsSong[setlist.id] = false;
        }
      }

      if (mounted) {
        setState(() {
          _setlists = setlists;
          _setlistContainsSong = setlistContainsSong;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching setlists: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load setlists';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _newSetlistController.dispose();
    super.dispose();
  }

  void _toggleCreateSetlist() {
    setState(() {
      _isCreatingNewSetlist = !_isCreatingNewSetlist;
    });
  }

  Future<void> _createNewSetlist() async {
    if (_newSetlistController.text.trim().isNotEmpty) {
      try {
        setState(() {
          _isCreatingSetlist = true;
        });

        // Create the setlist using the service
        final setlist = await _setlistService.createSetlist(
          _newSetlistController.text.trim(),
          description: 'Created from song detail screen',
        );

        // Add the song to the setlist
        await _setlistService.addSongToSetlist(setlist.id, widget.song.id);

        // Update the UI
        setState(() {
          _setlists.add(setlist);
          _setlistContainsSong[setlist.id] = true; // Mark as containing the song
          _isCreatingNewSetlist = false;
          _isCreatingSetlist = false;
          _newSetlistController.clear();
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Setlist created and song added!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error creating setlist: $e');

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create setlist: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _isCreatingSetlist = false;
        });
      }
    }
  }

  // Toggle song in setlist (add or remove)
  Future<void> _toggleSongInSetlist(String setlistId) async {
    try {
      setState(() {
        _isSavingSelections = true;
      });

      final bool isCurrentlyInSetlist = _setlistContainsSong[setlistId] ?? false;

      if (isCurrentlyInSetlist) {
        // Remove the song from the setlist
        await _setlistService.removeSongFromSetlist(setlistId, widget.song.id);

        // Update the state
        setState(() {
          _setlistContainsSong[setlistId] = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song removed from setlist'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add the song to the setlist
        await _setlistService.addSongToSetlist(setlistId, widget.song.id);

        // Update the state
        setState(() {
          _setlistContainsSong[setlistId] = true;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song added to setlist!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling song in setlist: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setlist: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSelections = false;
        });
      }
    }
  }

  // Save all selections and close the bottom sheet
  void _saveAndClose() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setlists updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Close the bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add to Setlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Song info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                // Song thumbnail placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(width: 12),
                // Song details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.song.artist,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Create new setlist button
          if (!_isCreatingNewSetlist)
            InkWell(
              onTap: _toggleCreateSetlist,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.add, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create New Setlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Create new setlist form
          if (_isCreatingNewSetlist)
            Column(
              children: [
                TextField(
                  controller: _newSetlistController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Setlist name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.black.withAlpha(50),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreatingSetlist ? null : _toggleCreateSetlist,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isCreatingSetlist ? null : _createNewSetlist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: _isCreatingSetlist
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Loading indicator
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
          ],

          // Error message
          if (_errorMessage != null && !_isCreatingNewSetlist) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSetlists,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Existing setlists
          if (!_isCreatingNewSetlist && !_isLoading && _errorMessage == null) ...[
            const Text(
              'Your Setlists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _setlists.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No setlists found. Create your first setlist!',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _setlists.length,
                      itemBuilder: (context, index) {
                        final setlist = _setlists[index];
                        final isInSetlist = _setlistContainsSong[setlist.id] ?? false;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.queue_music, color: Colors.white),
                          ),
                          title: Text(
                            setlist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${setlist.songs?.length ?? 0} songs',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: _isSavingSelections && _setlistContainsSong[setlist.id] != isInSetlist
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              )
                            : Checkbox(
                                value: isInSetlist,
                                activeColor: AppTheme.primary,
                                checkColor: Colors.black,
                                onChanged: (_) => _toggleSongInSetlist(setlist.id),
                              ),
                          onTap: () => _toggleSongInSetlist(setlist.id),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
          ],

          // Add padding at the bottom for better UX with bottom navigation bar
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
