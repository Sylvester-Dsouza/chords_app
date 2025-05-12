import 'package:flutter/material.dart';
import '../services/customer_service.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  bool _hasActiveSubscription = false;
  bool isAdFree = false;
  List<Map<String, dynamic>> _subscriptionPlans = [];
  Map<String, dynamic>? _activeSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  // Load subscription data
  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Run these requests in parallel for better performance
      final futures = await Future.wait([
        _customerService.hasAdsRemoved(),
        _customerService.hasActiveSubscription(),
        _customerService.getActiveSubscription(),
        _customerService.getSubscriptionPlans(),
      ]);

      if (mounted) {
        setState(() {
          isAdFree = futures[0] as bool;
          _hasActiveSubscription = futures[1] as bool;
          _activeSubscription = futures[2] as Map<String, dynamic>?;
          _subscriptionPlans = futures[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Format date for display
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Remove Ads'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Ad-Free Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a subscription plan to remove ads and support our app.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status section for active subscriptions or ad-free status
                    if (isAdFree || _hasActiveSubscription)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAdFree
                                        ? 'You currently have an ad-free experience!'
                                        : 'You have an active subscription!',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_hasActiveSubscription && _activeSubscription != null) ...[
                              const SizedBox(height: 12),
                              const Divider(color: Colors.green),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.card_membership,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan: ${_activeSubscription!['plan']?['name'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Renewal: ${_formatDate(_activeSubscription!['renewalDate'])}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    
                    // Message about AdMob removal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Ads Have Been Removed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We\'ve temporarily removed ads from the app to improve stability. Subscription features will be coming soon!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.thumb_up),
                              label: const Text('Great!'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
