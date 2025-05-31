import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_request.dart';
import '../services/song_request_service.dart';
import '../providers/user_provider.dart';

class SongRequestScreen extends StatefulWidget {
  const SongRequestScreen({super.key});

  @override
  State<SongRequestScreen> createState() => _SongRequestScreenState();
}

class _SongRequestScreenState extends State<SongRequestScreen> {
  final SongRequestService _songRequestService = SongRequestService();
  List<SongRequest> _songRequests = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchSongRequests();
  }

  void _checkLoginStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoggedIn = userProvider.isLoggedIn;
    });
  }

  Future<void> _fetchSongRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _songRequestService.getAllSongRequests();

      // Debug the hasUpvoted property for each request
      debugPrint('📋 Loaded ${requests.length} song requests from API:');
      for (var request in requests) {
        debugPrint('  🎵 ${request.songName} by ${request.artistName ?? "Unknown"} - hasUpvoted: ${request.hasUpvoted} (${request.upvotes} votes)');
      }

      setState(() {
        // Use the server state directly - it already includes the correct hasUpvoted status from the database
        _songRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching song requests: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load song requests');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddSongRequestBottomSheet() {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddSongRequestForm(
        onSongRequestAdded: (newRequest) {
          setState(() {
            _songRequests.add(newRequest);
          });
          _showSuccessSnackBar('Song request submitted successfully');
        },
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Login Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You need to be logged in to request songs.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              'Login',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpvote(SongRequest request) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    debugPrint('Handling upvote for song request: ${request.id} - Current hasUpvoted: ${request.hasUpvoted}');

    // Update the UI immediately before API call to provide instant feedback
    bool newUpvoteState = !request.hasUpvoted; // Toggle the state
    int newUpvoteCount = newUpvoteState ? request.upvotes + 1 : request.upvotes - 1;

    // Create updated request object
    final updatedRequest = SongRequest(
      id: request.id,
      songName: request.songName,
      artistName: request.artistName,
      youtubeLink: request.youtubeLink,
      spotifyLink: request.spotifyLink,
      notes: request.notes,
      status: request.status,
      upvotes: newUpvoteCount,
      customerId: request.customerId,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      hasUpvoted: newUpvoteState, // Set to the new state
    );

    // Update UI immediately
    setState(() {
      final index = _songRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _songRequests[index] = updatedRequest;
        debugPrint('Updated UI for song request: ${request.id} - New hasUpvoted: $newUpvoteState');
      }
    });

    // Make API call in the background without refreshing the list
    try {
      bool success;

      if (!newUpvoteState) {
        // We're removing an upvote
        success = await _songRequestService.removeUpvote(request.id);
        debugPrint('Removed upvote, success: $success');
      } else {
        // We're adding an upvote
        success = await _songRequestService.upvoteSongRequest(request.id);
        debugPrint('Added upvote, success: $success');
      }

      if (!success) {
        // If API call failed, revert the UI change
        debugPrint('API call failed, reverting UI change');
        setState(() {
          final index = _songRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final revertedRequest = SongRequest(
              id: request.id,
              songName: request.songName,
              artistName: request.artistName,
              youtubeLink: request.youtubeLink,
              spotifyLink: request.spotifyLink,
              notes: request.notes,
              status: request.status,
              upvotes: request.upvotes, // Original upvote count
              customerId: request.customerId,
              createdAt: request.createdAt,
              updatedAt: request.updatedAt,
              hasUpvoted: request.hasUpvoted, // Original upvote state
            );
            _songRequests[index] = revertedRequest;
          }
        });
        _showErrorSnackBar('Failed to update upvote');
      }
    } catch (e) {
      debugPrint('Error handling upvote: $e');

      // Handle specific error cases
      if (e.toString().contains('already upvoted')) {
        debugPrint('User already upvoted this request');
        // Keep the UI showing as upvoted (already updated above)
      } else if (e.toString().contains('not upvoted')) {
        debugPrint('User has not upvoted this request');
        // Keep the UI showing as not upvoted (already updated above)
      } else {
        // For other errors, revert the UI change
        setState(() {
          final index = _songRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final revertedRequest = SongRequest(
              id: request.id,
              songName: request.songName,
              artistName: request.artistName,
              youtubeLink: request.youtubeLink,
              spotifyLink: request.spotifyLink,
              notes: request.notes,
              status: request.status,
              upvotes: request.upvotes, // Original upvote count
              customerId: request.customerId,
              createdAt: request.createdAt,
              updatedAt: request.updatedAt,
              hasUpvoted: request.hasUpvoted, // Original upvote state
            );
            _songRequests[index] = revertedRequest;
          }
        });
        _showErrorSnackBar('Failed to update upvote');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Song'),
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Header with explanation text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Fill in the song name, artist name, and optionally, Spotify and YouTube links. Click "Submit" to send your request. You\'ll receive a confirmation, and your requested song will be added in due course. Enjoy the music!',
              style: const TextStyle(
                color: Color(0xB3FFFFFF), // White with 70% opacity
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Song request list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _songRequests.isEmpty
                    ? Center(
                        child: const Text(
                          'No song requests yet',
                          style: TextStyle(
                            color: Color(0xB3FFFFFF), // White with 70% opacity
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchSongRequests,
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.builder(
                          itemCount: _songRequests.length,
                          itemBuilder: (context, index) {
                            final request = _songRequests[index];
                            return _buildSongRequestItem(request);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSongRequestBottomSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      // Bottom navigation bar removed
    );
  }

  Widget _buildSongRequestItem(SongRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Further reduced from 4 to 2
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6), // Slightly smaller radius
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Further reduced padding
        dense: true, // Makes ListTile more compact
        title: Text(
          request.songName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14, // Further reduced from 15
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          request.artistName ?? 'Unknown Artist',
          style: const TextStyle(
            color: Color(0xB3FFFFFF), // White with 70% opacity
            fontSize: 12, // Further reduced from 13
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Container(
          width: 42, // Further reduced from 50
          height: 42, // Further reduced from 50
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                request.upvotes.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Further reduced from 16
                ),
              ),
              const Text(
                'Votes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 8, // Further reduced from 10
                ),
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 44, // Further reduced from 50
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _handleUpvote(request),
                child: Icon(
                  request.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: request.hasUpvoted ? Theme.of(context).colorScheme.primary : Colors.grey,
                  size: 20, // Further reduced from 22
                ),
              ),
              Text(
                'Upvote',
                style: TextStyle(
                  color: request.hasUpvoted ? Theme.of(context).colorScheme.primary : Colors.grey,
                  fontSize: 8, // Further reduced from 9
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSongRequestForm extends StatefulWidget {
  final Function(SongRequest) onSongRequestAdded;

  const _AddSongRequestForm({required this.onSongRequestAdded});

  @override
  State<_AddSongRequestForm> createState() => _AddSongRequestFormState();
}

class _AddSongRequestFormState extends State<_AddSongRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _songNameController = TextEditingController();
  final _artistNameController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final _spotifyLinkController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _songNameController.dispose();
    _artistNameController.dispose();
    _youtubeLinkController.dispose();
    _spotifyLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final songRequestService = SongRequestService();
      final newRequest = await songRequestService.createSongRequest(
        songName: _songNameController.text.trim(),
        artistName: _artistNameController.text.trim(),
        youtubeLink: _youtubeLinkController.text.trim(),
        spotifyLink: _spotifyLinkController.text.trim(),
        notes: _notesController.text.trim(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (newRequest != null) {
        widget.onSongRequestAdded(newRequest);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit song request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the available height for the bottom sheet
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: keyboardHeight + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: availableHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Request Song',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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

          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Song Name
                    TextFormField(
                      controller: _songNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Song Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a song name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Artist Name
                    TextFormField(
                      controller: _artistNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Artist Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // YouTube Link
                    TextFormField(
                      controller: _youtubeLinkController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Youtube Link',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Spotify Link
                    TextFormField(
                      controller: _spotifyLinkController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Spotify Link',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Additional notes (optional)',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(128), // Primary color with 50% opacity
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
