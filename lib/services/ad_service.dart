import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/customer_service.dart';

class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad units
  // Test ad units - replace with your actual ad units in production
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdiOS = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialAdUnitIdiOS = 'ca-app-pub-3940256099942544/4411468910';

  static const String _testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdiOS = 'ca-app-pub-3940256099942544/1712485313';

  // Production ad units - replace these with your actual ad units
  static const String _bannerAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';
  static const String _bannerAdUnitIdiOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';

  static const String _interstitialAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';
  static const String _interstitialAdUnitIdiOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';

  static const String _rewardedAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';
  static const String _rewardedAdUnitIdiOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';

  // Test device IDs - add your test devices here
  static const List<String> _testDeviceIds = [
    'YOUR_SAMSUNG_TEST_DEVICE_ID_HERE', // Add your Samsung test device ID here
  ];

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Ad states
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isAdFree = false;

  // Getters
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdReady => _isBannerAdReady && !_isAdFree;
  bool get isInterstitialAdReady => _isInterstitialAdReady && !_isAdFree;
  bool get isRewardedAdReady => _isRewardedAdReady && !_isAdFree;
  bool get isAdFree => _isAdFree;

  // Initialize the AdMob SDK
  Future<void> initialize() async {
    debugPrint('Initializing AdMob...');

    // Check if user has purchased ad-free experience
    await _checkAdFreeStatus();

    if (_isAdFree) {
      debugPrint('User has ad-free experience. Skipping ad initialization.');
      return;
    }

    // Initialize the Google Mobile Ads SDK
    await MobileAds.instance.initialize();

    // Set up test device IDs
    final RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: _testDeviceIds,
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    // Load a banner ad
    await _loadBannerAd();

    // Preload an interstitial ad
    await _loadInterstitialAd();

    // Preload a rewarded ad
    await _loadRewardedAd();
  }

  // Check if user has purchased ad-free experience or has an active subscription
  Future<void> _checkAdFreeStatus() async {
    try {
      // First check local storage for ad-free status
      final prefs = await SharedPreferences.getInstance();
      bool localAdFreeStatus = prefs.getBool('isAdFree') ?? false;

      // Then check if user has an active subscription
      final customerService = CustomerService();
      bool hasSubscription = false;

      try {
        // Check if ads are removed on the server
        final adsRemoved = await customerService.hasAdsRemoved();

        // If ads are removed on the server, update local status
        if (adsRemoved) {
          localAdFreeStatus = true;
          await prefs.setBool('isAdFree', true);
        }

        // Also check for active subscription
        hasSubscription = await customerService.hasActiveSubscription();
      } catch (apiError) {
        debugPrint('Error checking subscription status: $apiError');
        // Continue with local status if API check fails
      }

      // User is ad-free if they have purchased ad removal or have an active subscription
      _isAdFree = localAdFreeStatus || hasSubscription;
      debugPrint('Ad-free status: $_isAdFree (local: $localAdFreeStatus, subscription: $hasSubscription)');
    } catch (e) {
      debugPrint('Error checking ad-free status: $e');
      _isAdFree = false;
    }
  }

  // Set ad-free status
  Future<void> setAdFree(bool isAdFree) async {
    try {
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdFree', isAdFree);
      _isAdFree = isAdFree;
      debugPrint('Set ad-free status to: $_isAdFree');

      // Update server status if user is authenticated
      final customerService = CustomerService();
      if (isAdFree) {
        // Try to remove ads on the server
        try {
          final success = await customerService.removeAds();
          debugPrint('Server ad removal ${success ? 'successful' : 'failed'}');
        } catch (apiError) {
          debugPrint('Error removing ads on server: $apiError');
          // Continue with local changes even if API call fails
        }

        // Dispose of any loaded ads
        _disposeBannerAd();
        _disposeInterstitialAd();
        _disposeRewardedAd();
      } else {
        // Try to restore ads on the server (for testing purposes)
        try {
          final success = await customerService.restoreAds();
          debugPrint('Server ad restoration ${success ? 'successful' : 'failed'}');
        } catch (apiError) {
          debugPrint('Error restoring ads on server: $apiError');
          // Continue with local changes even if API call fails
        }

        // Reload ads
        await _loadBannerAd();
        await _loadInterstitialAd();
        await _loadRewardedAd();
      }
    } catch (e) {
      debugPrint('Error setting ad-free status: $e');
    }
  }

  // Get the appropriate banner ad unit ID based on platform
  String get _bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testBannerAdUnitIdAndroid : _testBannerAdUnitIdiOS;
    }
    return Platform.isAndroid ? _bannerAdUnitIdAndroid : _bannerAdUnitIdiOS;
  }

  // Get the appropriate interstitial ad unit ID based on platform
  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testInterstitialAdUnitIdAndroid : _testInterstitialAdUnitIdiOS;
    }
    return Platform.isAndroid ? _interstitialAdUnitIdAndroid : _interstitialAdUnitIdiOS;
  }

  // Get the appropriate rewarded ad unit ID based on platform
  String get _rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testRewardedAdUnitIdAndroid : _testRewardedAdUnitIdiOS;
    }
    return Platform.isAndroid ? _rewardedAdUnitIdAndroid : _rewardedAdUnitIdiOS;
  }

  // Load a banner ad
  Future<void> _loadBannerAd() async {
    if (_isAdFree) return;

    _disposeBannerAd();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('Banner ad loaded');
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          _isBannerAdReady = false;
          ad.dispose();
          _bannerAd = null;

          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), _loadBannerAd);
        },
      ),
    );

    await _bannerAd?.load();
  }

  // Load an interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (_isAdFree) return;

    _disposeInterstitialAd();

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Set callback for when the ad is closed
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Load the next interstitial ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Try loading again
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          _interstitialAd = null;

          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
        },
      ),
    );
  }

  // Load a rewarded ad
  Future<void> _loadRewardedAd() async {
    if (_isAdFree) return;

    _disposeRewardedAd();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          // Set callback for when the ad is closed
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              _loadRewardedAd(); // Load the next rewarded ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: ${error.message}');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              _loadRewardedAd(); // Try loading again
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _isRewardedAdReady = false;
          _rewardedAd = null;

          // Retry loading after a delay
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  // Show an interstitial ad
  Future<bool> showInterstitialAd() async {
    if (_isAdFree) return false;

    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
      _isInterstitialAdReady = false;
      return true;
    } else {
      debugPrint('Interstitial ad not ready yet');
      await _loadInterstitialAd();
      return false;
    }
  }

  // Show a rewarded ad
  Future<bool> showRewardedAd({required Function(RewardItem reward) onRewarded}) async {
    if (_isAdFree) return false;

    if (_isRewardedAdReady && _rewardedAd != null) {
      await _rewardedAd!.show(onUserEarnedReward: (_, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onRewarded(reward);
      });
      _isRewardedAdReady = false;
      return true;
    } else {
      debugPrint('Rewarded ad not ready yet');
      await _loadRewardedAd();
      return false;
    }
  }

  // Dispose of the banner ad
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }

  // Dispose of the interstitial ad
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  // Dispose of the rewarded ad
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }

  // Dispose of all ads
  void dispose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
    _disposeRewardedAd();
  }
}
