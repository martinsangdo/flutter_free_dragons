import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Mobile (Android/iOS) implementation of the ads service: initialization,
/// ad-unit IDs, and the rewarded ad used for hints. Banners are loaded by the
/// mobile `AdBanner` widget using [bannerUnitId].
///
/// Debug builds use Google's official **test** ad units (they always fill and
/// are never billable); swap in the real production units (marked TODO) before
/// shipping. This file is only ever compiled on platforms with `dart:io` — Web
/// gets the no-op stub instead.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;

  /// Initialize the Mobile Ads SDK and warm a rewarded ad. Safe to call once at
  /// startup. Wrapped so an unsupported platform (e.g. desktop, which has no ad
  /// plugin) can't crash app launch.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
    } catch (_) {
      // Ads simply stay unavailable; the app runs normally without them.
    }
  }

  // --- Ad unit IDs -----------------------------------------------------------

  static String get bannerUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // TODO: replace with the real production banner unit IDs before release.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get _rewardedUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    // TODO: replace with the real production rewarded unit IDs before release.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }

  // --- Rewarded ad -----------------------------------------------------------

  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _loadingRewarded = false;
        },
      ),
    );
  }

  /// Whether a rewarded ad is loaded and ready to show right now.
  bool get isRewardedReady => _rewarded != null;

  /// Show the rewarded ad, completing `true` when the reward should be granted.
  ///
  /// Intentionally **fail-open**: when no ad is loaded, or the ad fails to
  /// present, it grants the reward anyway so a missing ad never blocks a hint.
  /// A fresh ad is preloaded for next time.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return true;
    }
    _rewarded = null;

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }
}
