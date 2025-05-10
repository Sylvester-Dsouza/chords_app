import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdService _adService = AdService();

  @override
  Widget build(BuildContext context) {
    if (!_adService.isBannerAdReady || _adService.bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _adService.bannerAd!.size.width.toDouble(),
      height: _adService.bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _adService.bannerAd!),
    );
  }
}
