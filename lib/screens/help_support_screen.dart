import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';
import '../config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/+919876543210?text=Hello,%20I%20need%20help%20with%20the%20Christian%20Chords%20app.');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUrl = Uri.parse('mailto:support@christianchords.com?subject=App%20Support%20Request&body=Hello,%20I%20need%20help%20with%20the%20Christian%20Chords%20app.');

    try {
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        throw 'Could not launch Email';
      }
    } catch (e) {
      debugPrint('Error launching Email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Help & Support',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'How can we help you?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Get in touch with our support team for any questions or issues.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // WhatsApp Support
              _buildSupportCard(
                context,
                icon: Icons.message,
                title: 'WhatsApp Support',
                description: 'Chat with our support team directly via WhatsApp for quick assistance.',
                buttonText: 'Chat Now',
                iconColor: const Color(0xFF25D366),
                onTap: _launchWhatsApp,
              ),

              const SizedBox(height: 16),

              // Email Support
              _buildSupportCard(
                context,
                icon: Icons.email,
                title: 'Email Support',
                description: 'Send us an email with your query and we\'ll get back to you within 24 hours.',
                buttonText: 'Send Email',
                iconColor: const Color(0xFF4285F4),
                onTap: _launchEmail,
              ),

              const SizedBox(height: 32),

              // FAQ Section
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildFaqItem(
                context,
                question: 'How do I create a setlist?',
                answer: 'To create a setlist, go to the Setlist tab, tap on the "+" button, enter a name for your setlist, and tap "Create".',
              ),

              _buildFaqItem(
                context,
                question: 'How do I transpose a song?',
                answer: 'On the song detail screen, use the transpose controls at the bottom to change the key of the song.',
              ),

              _buildFaqItem(
                context,
                question: 'Can I use the app offline?',
                answer: 'Yes, once you\'ve viewed a song, it will be cached for offline use. Your setlists and liked songs will also be available offline.',
              ),

              _buildFaqItem(
                context,
                question: 'How do I report an issue with a song?',
                answer: 'On the song detail screen, tap the menu icon and select "Report Issue" to send feedback about any problems with the song.',
              ),

              const SizedBox(height: 32),

              // Support Hours
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Hours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Monday - Friday: 9:00 AM - 6:00 PM IST\nSaturday: 10:00 AM - 2:00 PM IST\nSunday: Closed',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26), // 0.1 * 255 ≈ 26
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: AppTheme.primaryColor,
      collapsedIconColor: Colors.grey,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
