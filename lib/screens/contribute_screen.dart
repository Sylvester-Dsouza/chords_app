import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../utils/toast_util.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _songTitleController = TextEditingController();
  final _artistController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _chordsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedLanguage = 'English';
  String _selectedDifficulty = 'Medium';
  
  final List<String> _languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam', 'Kannada', 'Other'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _songTitleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _chordsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitContribution() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        // Show success message
        ToastUtil.showSuccess(context, 'Thank you for your contribution!');
        
        // Clear form
        _songTitleController.clear();
        _artistController.clear();
        _lyricsController.clear();
        _chordsController.clear();
        _notesController.clear();
        setState(() {
          _selectedLanguage = 'English';
          _selectedDifficulty = 'Medium';
        });
        
        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        if (!mounted) return;
        ToastUtil.showError(context, 'Failed to submit contribution. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoggedIn = userProvider.isLoggedIn;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Contribute',
      ),
      body: isLoggedIn 
        ? _buildContributeForm() 
        : _buildLoginPrompt(context),
      bottomNavigationBar: isLoggedIn 
        ? _buildSubmitButton() 
        : null,
    );
  }
  
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              color: Color(0xFFFFC701),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You need to be logged in to contribute songs to our community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC701),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContributeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contribute a Song',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your favorite worship songs with the community.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Song Title
            _buildTextField(
              controller: _songTitleController,
              label: 'Song Title',
              hint: 'Enter the song title',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the song title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Artist
            _buildTextField(
              controller: _artistController,
              label: 'Artist/Band',
              hint: 'Enter the artist or band name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the artist name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Language and Difficulty
            Row(
              children: [
                // Language Dropdown
                Expanded(
                  child: _buildDropdown(
                    label: 'Language',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Difficulty Dropdown
                Expanded(
                  child: _buildDropdown(
                    label: 'Difficulty',
                    value: _selectedDifficulty,
                    items: _difficulties,
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lyrics
            _buildTextField(
              controller: _lyricsController,
              label: 'Lyrics',
              hint: 'Enter the song lyrics',
              maxLines: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the lyrics';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Chords
            _buildTextField(
              controller: _chordsController,
              label: 'Chords (Optional)',
              hint: 'Enter the chords in square brackets [C] before the lyrics',
              maxLines: 8,
              validator: null,
            ),
            
            const SizedBox(height: 16),
            
            // Additional Notes
            _buildTextField(
              controller: _notesController,
              label: 'Additional Notes (Optional)',
              hint: 'Any additional information about the song',
              maxLines: 3,
              validator: null,
            ),
            
            const SizedBox(height: 24),
            
            // Formatting Guide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF333333),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Formatting Guide',
                    style: TextStyle(
                      color: Color(0xFFFFC701),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Place chords in square brackets before the word they belong to: [G]Amazing [D]grace\n'
                    '• Use a blank line to separate verses and choruses\n'
                    '• Mark chorus with "Chorus:" on its own line\n'
                    '• Mark bridge with "Bridge:" on its own line',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(
            color: Color(0xFF333333),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitContribution,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC701),
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                )
              : const Text(
                  'Submit Contribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
