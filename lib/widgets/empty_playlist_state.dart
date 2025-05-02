import 'package:flutter/material.dart';

class EmptyPlaylistState extends StatelessWidget {
  final VoidCallback onCreatePlaylist;
  
  const EmptyPlaylistState({
    super.key,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty illustration
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.queue_music,
              size: 80,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          
          // Empty text
          const Text(
            'No Playlists Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Create your first playlist to organize your favorite songs',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Create button
          ElevatedButton(
            onPressed: onCreatePlaylist,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC701),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text(
                  'Create Playlist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
