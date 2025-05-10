import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isQrExpanded = false;
  
  // Support platform links
  final Map<String, String> _supportLinks = {
    'Ko-fi': 'https://ko-fi.com/worshipparadise',
    'Patreon': 'https://www.patreon.com/worshipparadise',
    'Buy Me a Coffee': 'https://www.buymeacoffee.com/worshipparadise',
    'GitHub Sponsors': 'https://github.com/sponsors/worshipparadise',
  };
  
  // Bank details
  final Map<String, String> _bankDetails = {
    'Account Name': 'Worship Paradise',
    'Account Number': '1234567890',
    'Bank Name': 'Example Bank',
    'IFSC Code': 'EXMP0001234',
    'Branch': 'Main Branch',
  };
  
  // UPI details
  final String _upiId = 'worshipparadise@upi';
  final String _upiQrData = 'upi://pay?pa=worshipparadise@upi&pn=Worship%20Paradise&am=&cu=INR';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Support Worship Paradise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Online Platforms'),
            Tab(text: 'Bank Transfer'),
            Tab(text: 'UPI / QR Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOnlinePlatformsTab(),
          _buildBankTransferTab(),
          _buildUpiQrCodeTab(),
        ],
      ),
    );
  }

  // Tab 1: Online Platforms (Ko-fi, Patreon, etc.)
  Widget _buildOnlinePlatformsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Support Us Online'),
          const SizedBox(height: 16),
          const Text(
            'Choose your preferred platform to support our work. Every contribution helps us improve the app and add new features!',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Platform cards
          ..._supportLinks.entries.map((entry) => _buildPlatformCard(
            platform: entry.key,
            url: entry.value,
            icon: _getPlatformIcon(entry.key),
          )).toList(),
          
          const SizedBox(height: 24),
          _buildShareAppSection(),
        ],
      ),
    );
  }

  // Tab 2: Bank Transfer
  Widget _buildBankTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Bank Transfer Details'),
          const SizedBox(height: 16),
          const Text(
            'You can support us directly through a bank transfer using the details below:',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Bank details card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _bankDetails.entries.map((entry) => _buildDetailRow(
                label: entry.key,
                value: entry.value,
                canCopy: entry.key != 'Bank Name' && entry.key != 'Branch',
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Note: Please include "Worship Paradise Support" in the transfer description so we can identify your contribution.',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // Tab 3: UPI / QR Code
  Widget _buildUpiQrCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('UPI Payment'),
          const SizedBox(height: 16),
          const Text(
            'Scan the QR code below or use our UPI ID to make a quick payment:',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // UPI ID card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: _buildDetailRow(
              label: 'UPI ID',
              value: _upiId,
              canCopy: true,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // QR Code
          GestureDetector(
            onTap: () {
              setState(() {
                _isQrExpanded = !_isQrExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: _isQrExpanded ? 300 : 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: _upiQrData,
                    version: QrVersions.auto,
                    size: _isQrExpanded ? 250 : 150,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isQrExpanded ? 'Tap to shrink' : 'Tap to enlarge',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in UPI App'),
              onPressed: () => _launchUrl('upi://pay?pa=$_upiId&pn=Worship%20Paradise&am=&cu=INR'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildPlatformCard({
    required String platform,
    required String url,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          platform,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text(
          'Support us on this platform',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () => _launchUrl(url),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool canCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyToClipboard(value),
            ),
        ],
      ),
    );
  }

  Widget _buildShareAppSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Another way to support us',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share the app with your friends and community to help us grow!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share App'),
            onPressed: _shareApp,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Ko-fi':
        return Icons.coffee;
      case 'Patreon':
        return Icons.favorite;
      case 'Buy Me a Coffee':
        return Icons.local_cafe;
      case 'GitHub Sponsors':
        return Icons.code;
      default:
        return Icons.attach_money;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareApp() {
    Share.share(
      'Check out Worship Paradise - a free app for worship song chords! Download it here: https://play.google.com/store/apps/details?id=com.worshipparadise.chords',
      subject: 'Worship Paradise - Free Worship Song Chords App',
    );
  }
}
