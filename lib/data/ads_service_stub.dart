/// Web / no-`dart:io` stub of [AdsService]. Ads are disabled here, so every
/// method is a safe no-op. [showRewarded] returns `true` (fail-open) so the
/// hint gating in the game screen still lets players get hints on Web.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// Unused on Web (the banner widget renders nothing there).
  static String get bannerUnitId => '';

  Future<void> init() async {}

  bool get isRewardedReady => false;

  Future<bool> showRewarded() async => true;
}
