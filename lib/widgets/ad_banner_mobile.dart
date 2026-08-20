import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/ads_service.dart';

/// An **Anchored Adaptive Banner** anchored to the bottom of the game screen.
///
/// It reserves the banner's vertical space up front (so the layout never shifts
/// when the ad fills in) and swaps in the live `AdWidget` once loaded.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  /// Fallback reserved height before the adaptive size is known — mirrors
  /// Google's guidance (90 on tablet-width screens, otherwise 50).
  static double reservedHeight(double width) => width >= 728 ? 90 : 50;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs MediaQuery for the adaptive width, so load here rather than in
    // initState — but only once.
    if (!_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;

    final banner = BannerAd(
      adUnitId: AdsService.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await banner.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final height = ad != null
        ? ad.size.height.toDouble()
        : AdBanner.reservedHeight(MediaQuery.of(context).size.width);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ad != null ? Center(child: AdWidget(ad: ad)) : null,
    );
  }
}
