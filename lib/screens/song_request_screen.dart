import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_request.dart';
import '../services/song_request_service.dart';
import '../providers/user_provider.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';

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
      setState(() {
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
            child: const Text(
              'Login',
              style: TextStyle(color: Color(0xFFFFC701)),
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

    try {
      bool success;
      if (request.hasUpvoted) {
        success = await _songRequestService.removeUpvote(request.id);
      } else {
        success = await _songRequestService.upvoteSongRequest(request.id);
      }

      if (success) {
        // Update the UI immediately before refreshing from the server
        setState(() {
          final index = _songRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final updatedRequest = SongRequest(
              id: request.id,
              songName: request.songName,
              artistName: request.artistName,
              youtubeLink: request.youtubeLink,
              spotifyLink: request.spotifyLink,
              notes: request.notes,
              status: request.status,
              upvotes: request.hasUpvoted ? request.upvotes - 1 : request.upvotes + 1,
              customerId: request.customerId,
              createdAt: request.createdAt,
              updatedAt: request.updatedAt,
              hasUpvoted: !request.hasUpvoted,
            );
            _songRequests[index] = updatedRequest;
          }
        });

        // Refresh the list from the server
        _fetchSongRequests();
      }
    } catch (e) {
      debugPrint('Error handling upvote: $e');

      // Check if the error is because the user already upvoted
      if (e.toString().contains('already upvoted')) {
        // Update the UI to show as upvoted
        setState(() {
          final index = _songRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final updatedRequest = SongRequest(
              id: request.id,
              songName: request.songName,
              artistName: request.artistName,
              youtubeLink: request.youtubeLink,
              spotifyLink: request.spotifyLink,
              notes: request.notes,
              status: request.status,
              upvotes: request.upvotes,
              customerId: request.customerId,
              createdAt: request.createdAt,
              updatedAt: request.updatedAt,
              hasUpvoted: true,
            );
            _songRequests[index] = updatedRequest;
          }
        });
      } else {
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
      ),
      drawer: const AppDrawer(),
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFC701),
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
                        color: const Color(0xFFFFC701),
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
        backgroundColor: const Color(0xFFFFC701),
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation based on the index
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1: // My Playlist
              Navigator.pushReplacementNamed(context, '/playlist');
              break;
            case 2: // Search
              Navigator.pushReplacementNamed(context, '/search');
              break;
            case 3: // Resources
              Navigator.pushReplacementNamed(context, '/resources');
              break;
            case 4: // Profile
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildSongRequestItem(SongRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          request.songName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              request.artistName ?? 'Unknown Artist',
              style: const TextStyle(
                color: Color(0xB3FFFFFF), // White with 70% opacity
                fontSize: 14,
              ),
            ),
          ],
        ),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  request.upvotes.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Votes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: SizedBox(
          width: 56, // Fixed width to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _handleUpvote(request),
                child: Icon(
                  request.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: request.hasUpvoted ? const Color(0xFF4CAF50) : Colors.grey, // Green when upvoted
                  size: 24, // Explicit size
                ),
              ),
              const SizedBox(height: 2), // Add a small gap
              const Text(
                'Upvote',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10, // Smaller font size
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
              backgroundColor: const Color(0xFFFFC701),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: const Color(0x80FFC701), // FFC701 with 50% opacity
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
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
