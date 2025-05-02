import 'package:flutter/material.dart';
import '../widgets/inner_screen_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Privacy Policy',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().substring(0, 10)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildPolicySection(
              title: 'Introduction',
              content: 'Welcome to Christian Chords. We respect your privacy and are committed to protecting your personal data. This Privacy Policy will inform you about how we look after your personal data when you use our application and tell you about your privacy rights and how the law protects you.',
            ),
            
            _buildPolicySection(
              title: 'Data We Collect',
              content: 'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:\n\n'
                  '• Personal Data: Name, email address, and profile information.\n'
                  '• Usage Data: Information about how you use our application, including your song preferences, playlists, and interaction with the app features.\n'
                  '• Technical Data: Internet protocol (IP) address, your login data, browser type and version, device type, and other technology on the devices you use to access our application.',
            ),
            
            _buildPolicySection(
              title: 'How We Use Your Data',
              content: 'We use your data to:\n\n'
                  '• Provide and maintain our service\n'
                  '• Notify you about changes to our service\n'
                  '• Allow you to participate in interactive features of our service\n'
                  '• Provide customer support\n'
                  '• Gather analysis or valuable information so that we can improve our service\n'
                  '• Monitor the usage of our service\n'
                  '• Detect, prevent and address technical issues',
            ),
            
            _buildPolicySection(
              title: 'Data Security',
              content: 'We have implemented appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way, altered, or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors, and other third parties who have a business need to know.',
            ),
            
            _buildPolicySection(
              title: 'Third-Party Services',
              content: 'Our application may contain links to third-party websites or services that are not owned or controlled by us. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party websites or services.',
            ),
            
            _buildPolicySection(
              title: 'Children\'s Privacy',
              content: 'Our service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If you are a parent or guardian and you are aware that your child has provided us with personal data, please contact us.',
            ),
            
            _buildPolicySection(
              title: 'Changes to This Privacy Policy',
              content: 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date at the top of this Privacy Policy.',
            ),
            
            _buildPolicySection(
              title: 'Contact Us',
              content: 'If you have any questions about this Privacy Policy, please contact us:\n\n'
                  '• By email: privacy@christianchords.com\n'
                  '• By visiting this page on our website: www.christianchords.com/contact',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFC701),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
