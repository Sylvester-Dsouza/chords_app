import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of contributors
    final List<Map<String, String>> contributors = [
      {
        'name': 'Silvan Dsouza',
        'role': 'Marketing',
      },
      {
        'name': 'Silvan Dsouza',
        'role': 'Marketing',
      },
      {
        'name': 'Silvan Dsouza',
        'role': 'Marketing',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About us'),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // App name and tagline
              const Text(
                'Stuthi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Christian Chords & Lyrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // App description
              const Text(
                'Stuthi is a platform dedicated to providing high-quality chord sheets and lyrics for Christian worship songs. Our mission is to help worship teams and individual musicians access the resources they need to lead worship effectively.',
                style: TextStyle(
                  color: Color(0xB3FFFFFF), // White with 70% opacity
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'We strive to create a community where worship leaders and musicians can find, share, and contribute to a growing library of worship resources. Thank you for being part of our journey!',
                style: TextStyle(
                  color: Color(0xB3FFFFFF), // White with 70% opacity
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Contributors section
              const Text(
                'Contributors',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Contributors list
              ...contributors.map((contributor) => _buildContributorCard(context, contributor)),

              const SizedBox(height: 24),

              // Version info
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0x80FFFFFF), // White with 50% opacity
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Copyright info
              const Text(
                '© 2024 Stuthi. All rights reserved.',
                style: TextStyle(
                  color: Color(0x80FFFFFF), // White with 50% opacity
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // Bottom navigation bar removed from inner screens
    );
  }

  Widget _buildContributorCard(BuildContext context, Map<String, String> contributor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF333333),
          child: const Icon(
            Icons.person,
            color: Colors.grey,
          ),
        ),
        title: Text(
          contributor['name']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          contributor['role']!,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }
}
