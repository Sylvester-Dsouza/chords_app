import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _launchAppStore() async {
    // Replace with your actual app store links
    final Uri appStoreUrl = Uri.parse('https://apps.apple.com/app/yourappid');
    final Uri playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.yourapp.id');
    
    try {
      // Determine which store to open based on platform
      final Uri storeUrl = Theme.of(context).platform == TargetPlatform.iOS
          ? appStoreUrl
          : playStoreUrl;
      
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch store';
      }
    } catch (e) {
      debugPrint('Error launching store: $e');
      if (!mounted) return;
      ToastUtil.showError(context, 'Could not open app store. Please try again later.');
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ToastUtil.showError(context, 'Please select a rating');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Show success message
      ToastUtil.showSuccess(context, 'Thank you for your feedback!');
      
      // If rating is high (4-5), prompt to rate on app store
      if (_rating >= 4) {
        _showRateOnStoreDialog();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Failed to submit feedback. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showRateOnStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Rate on App Store',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Would you like to rate our app on the app store?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              _launchAppStore();
            },
            child: const Text(
              'Rate Now',
              style: TextStyle(color: Color(0xFFFFC701)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Rate App',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            
            // App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFFFFC701),
                size: 60,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Christian Chords',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'How would you rate your experience?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC701),
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: 32),
            
            // Feedback Text Field
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Tell us what you think (optional)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
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
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rate on Store Button
            TextButton.icon(
              onPressed: _launchAppStore,
              icon: const Icon(
                Icons.star,
                color: Color(0xFFFFC701),
              ),
              label: const Text(
                'Rate on App Store',
                style: TextStyle(
                  color: Color(0xFFFFC701),
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
