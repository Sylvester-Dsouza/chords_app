import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/customer_service.dart';
import '../providers/user_provider.dart';
import '../widgets/banner_ad_widget.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final AdService _adService = AdService();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  bool _hasActiveSubscription = false;
  List<Map<String, dynamic>> _subscriptionPlans = [];
  Map<String, dynamic>? _activeSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  // Load subscription data
  Future<void> _loadSubscriptionData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Run these requests in parallel for better performance
      final subscriptionFuture = _customerService.hasActiveSubscription();
      final plansFuture = _customerService.getSubscriptionPlans();

      // Wait for both requests to complete
      final hasSubscription = await subscriptionFuture;
      final plans = await plansFuture;

      // Get subscription details if user has an active subscription
      Map<String, dynamic>? subscription;
      if (hasSubscription) {
        subscription = await _customerService.getActiveSubscription();
      }

      if (mounted) {
        setState(() {
          _hasActiveSubscription = hasSubscription;
          _activeSubscription = subscription;
          _subscriptionPlans = plans;
          _isLoading = false;
        });

        // Log the number of plans for debugging
        debugPrint('Loaded ${plans.length} subscription plans');
        if (plans.isEmpty) {
          debugPrint('No subscription plans available');
        }
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final isAdFree = _adService.isAdFree;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Remove Ads'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner ad at the top (to show what will be removed)
              if (!isAdFree) ...[
                const Center(
                  child: Text(
                    'Current ads in the app:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: BannerAdWidget()),
                const SizedBox(height: 24),
              ],

              // Main content
              const Text(
                'Ad-Free Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enjoy Worship Paradise without any advertisements. Your support helps us continue to provide quality content and improve the app.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Benefits list
              _buildBenefitItem(
                icon: Icons.block,
                title: 'No Banner Ads',
                description: 'Remove all banner advertisements from the app',
              ),
              _buildBenefitItem(
                icon: Icons.skip_next,
                title: 'No Interstitial Ads',
                description: 'No more full-screen ads between screens',
              ),
              _buildBenefitItem(
                icon: Icons.speed,
                title: 'Faster Experience',
                description: 'Enjoy a smoother, faster app experience',
              ),
              _buildBenefitItem(
                icon: Icons.favorite,
                title: 'Support Development',
                description: 'Help us continue to improve the app',
              ),
              const SizedBox(height: 32),

              // Subscription options
              if (!isAdFree) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha(30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Subscription Plans',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Refresh button
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: _isLoading
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: _isLoading ? null : _loadSubscriptionData,
                            tooltip: 'Refresh subscription plans',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Subscribe to remove ads and get access to premium features. All subscription plans include ad-free experience for the duration of your subscription.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show loading indicator while fetching plans
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      // Show message when no plans are available
                      else if (_subscriptionPlans.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No subscription plans are currently available. Please check back later.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      // Show subscription plans
                      else
                        ..._subscriptionPlans.map((plan) => _buildSubscriptionPlanCard(plan, isLoggedIn)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
                )
              // One-time purchase option (only shown if no subscription and not ad-free)
              else if (!isAdFree && !_hasActiveSubscription)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'One-Time Purchase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Remove ads permanently with a single payment.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.block),
                          label: Text(_isLoading ? 'Processing...' : 'Remove Ads for \$2.99'),
                          onPressed: _isLoading || !isLoggedIn
                              ? null
                              : () => _showPurchaseConfirmation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(180),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (!isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: const Text(
                                'Login to remove ads',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Restore purchases button
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _restorePurchases,
                          child: const Text(
                            'Restore Purchases',
                            style: TextStyle(color: Colors.white70),
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

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Remove Ads',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Would you like to remove all ads from the app for \$2.99?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _purchaseAdRemoval();
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseAdRemoval() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would implement in-app purchase here
      // For now, we'll just simulate a successful purchase
      await Future.delayed(const Duration(seconds: 2));

      // Set ad-free status
      await _adService.setAdFree(true);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ads removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error purchasing ad removal: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Build a subscription plan card
  Widget _buildSubscriptionPlanCard(Map<String, dynamic> plan, bool isLoggedIn) {
    final String name = plan['name'] ?? 'Unknown Plan';
    final String description = plan['description'] ?? '';
    final double price = (plan['price'] is num) ? (plan['price'] as num).toDouble() : 0.0;
    final String billingCycle = plan['billingCycle'] ?? 'MONTHLY';
    final List<dynamic> features = plan['features'] ?? [];
    final bool isPopular = plan['isPopular'] == true;

    // Format billing cycle for display
    String cycleText = 'month';
    switch (billingCycle) {
      case 'MONTHLY':
        cycleText = 'month';
        break;
      case 'QUARTERLY':
        cycleText = '3 months';
        break;
      case 'ANNUAL':
        cycleText = 'year';
        break;
      case 'LIFETIME':
        cycleText = 'lifetime';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withAlpha(50),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular badge
          if (isPopular)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Plan content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      billingCycle == 'LIFETIME'
                          ? '\$${price.toStringAsFixed(2)}'
                          : '\$${price.toStringAsFixed(2)}/$cycleText',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Description if available
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                // Features list
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 16),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !isLoggedIn
                        ? null
                        : () => _subscribeToPlan(plan['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withAlpha(180),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isLoading ? 'Processing...' : 'Subscribe',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Login message
                if (!isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text(
                        'Login required to subscribe',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Subscribe to a plan
  Future<void> _subscribeToPlan(String planId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Subscribe to the plan
      final success = await _customerService.subscribeToPlan(planId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Update ad-free status
          await _adService.setAdFree(true);

          // Reload subscription data
          await _loadSubscriptionData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription successful! Ads have been removed.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to subscribe. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error subscribing to plan: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would implement restore purchases here
      // For now, we'll just simulate a restore
      await Future.delayed(const Duration(seconds: 2));

      // Check if the user has previously purchased ad removal
      // For demo purposes, we'll just show a message

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
