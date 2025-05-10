import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class PremiumContentScreen extends StatefulWidget {
  const PremiumContentScreen({super.key});

  @override
  State<PremiumContentScreen> createState() => _PremiumContentScreenState();
}

class _PremiumContentScreenState extends State<PremiumContentScreen> {
  final AdService _adService = AdService();
  bool _isLoading = false;
  bool _hasUnlockedContent = false;
  bool _isWatchingAd = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Premium Content'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium content header
              const Text(
                'Premium Chord Sheets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access premium chord sheets with advanced chord variations, strumming patterns, and detailed notes from professional musicians.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Premium content preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Premium Chord Sheet Example',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Blurred content when not unlocked
                    if (!_hasUnlockedContent)
                      Stack(
                        children: [
                          // Blurred content
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Premium content is locked',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          // Lock icon overlay
                          Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.lock,
                                color: Colors.white.withAlpha(150),
                                size: 48,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Actual premium content when unlocked
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amazing Grace',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Strumming Pattern: D DU UDU',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '[Verse 1]\nG       D/F#    Em    C\nAmazing grace how sweet the sound\nG        D          G\nThat saved a wretch like me\nG      D/F#    Em    C\nI once was lost but now am found\nG       D       G\nWas blind but now I see',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Unlock options
              if (!_hasUnlockedContent)
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Unlock Premium Content',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Watch ad button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(_isLoading ? 'Loading...' : 'Watch Ad to Unlock'),
                        onPressed: _isLoading ? null : _watchRewardedAd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subscription option
                      OutlinedButton.icon(
                        icon: const Icon(Icons.star),
                        label: const Text('Subscribe for Unlimited Access'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/remove-ads');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Content Unlocked!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.star),
                        label: const Text('Subscribe for More Premium Content'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/remove-ads');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _watchRewardedAd() async {
    setState(() {
      _isLoading = true;
      _isWatchingAd = true;
    });

    try {
      final bool adShown = await _adService.showRewardedAd(
        onRewarded: (RewardItem reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          setState(() {
            _hasUnlockedContent = true;
          });
        },
      );

      if (!adShown && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load ad. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWatchingAd = false;
        });
      }
    }
  }
}
