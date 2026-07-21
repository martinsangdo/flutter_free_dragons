import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reserved layout region for an **Anchored Adaptive Banner**.
///
/// This is an intentional placeholder — no real ad SDK is wired up yet. It
/// occupies the same vertical space a live banner would so the gameplay layout
/// doesn't shift when AdMob is added later. To turn this into a real ad:
///
///   1. Add `google_mobile_ads` to pubspec.yaml.
///   2. Compute the adaptive height via
///      `AdSize.getAnchoredAdaptiveBannerAdSize(...)`.
///   3. Load a `BannerAd` (use `AdRequest`; test unit IDs in debug — see below)
///      and render its `AdWidget` in place of the placeholder box.
///
/// Google test ad unit IDs (use in debug builds):
///   Android banner: ca-app-pub-3940256099942544/6300978111
///   iOS banner:     ca-app-pub-3940256099942544/2934735716
///
/// Ads are disabled entirely on Web ([kIsWeb]) per the spec.
class BannerAdPlaceholder extends StatelessWidget {
  const BannerAdPlaceholder({super.key});

  /// Approximate anchored-adaptive-banner height for the given screen width.
  /// Mirrors Google's guidance: 32 for short screens, 90 for tablets, else 50.
  static double heightForWidth(double width) {
    if (width >= 728) return 90;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    // No ads on the web build.
    if (kIsWeb) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final height = heightForWidth(width);

    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.boardBg.withOpacity(0.4),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '[ Banner Ad Placeholder ]',
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.6),
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
