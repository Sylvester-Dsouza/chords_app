import 'package:flutter/material.dart';

class CreatePlaylistDialog extends StatefulWidget {
  final Function(String name, String? description) onCreatePlaylist;
  
  const CreatePlaylistDialog({
    super.key,
    required this.onCreatePlaylist,
  });

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCreating = false;
  String? _nameError;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _validateAndCreate() {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Please enter a playlist name';
      });
      return;
    }
    
    setState(() {
      _isCreating = true;
      _nameError = null;
    });
    
    // Call the create function
    widget.onCreatePlaylist(
      _nameController.text.trim(),
      _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Create New Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Enter playlist name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                errorText: _nameError,
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFC701),
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.queue_music,
                  color: Colors.grey,
                ),
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() {
                    _nameError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Enter playlist description',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFC701),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                TextButton(
                  onPressed: _isCreating 
                      ? null 
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                
                // Create button
                ElevatedButton(
                  onPressed: _isCreating ? null : _validateAndCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC701),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Create',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
