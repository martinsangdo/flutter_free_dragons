import 'package:flutter/material.dart';
import '../data/app_prefs.dart';
import '../data/egg_sprites.dart';
import '../data/level_repository.dart';
import 'home_screen.dart';
import 'how_to_play_screen.dart';

/// White splash shown for at least 2 seconds. During that window it precaches
/// the logo and warms the [LevelRepository] (which, on first launch, generates
/// and verifies the procedural levels), then routes to the how-to-play screen
/// on first launch or straight to home afterwards.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logo = AssetImage('assets/images/logo.png');
  bool _preparing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache during the visible splash window so the first navigation is jank
    // free.
    precacheImage(_logo, context);
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final minSplash = Future<void>.delayed(const Duration(seconds: 2));
    // Decode the egg sprites here so the board never paints a goal block
    // without its artwork. Runs alongside level loading, not after it.
    final load = Future.wait([
      LevelRepository.instance.ensureLoaded(),
      EggSprites.load(),
    ]);

    // Keep the splash up for the nominal 2s. If first-launch generation runs
    // longer, show a subtle "preparing" note instead of a frozen screen.
    await minSplash;
    if (!LevelRepository.instance.isLoaded && mounted) {
      setState(() => _preparing = true);
    }
    await load;

    if (!mounted) return;
    final seenHowTo = await AppPrefs.hasSeenHowToPlay();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seenHowTo
            ? const HomeScreen()
            : const HowToPlayScreen(firstLaunch: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(image: _logo, width: 220, height: 220),
            const SizedBox(height: 32),
            SizedBox(
              height: 40,
              child: _preparing
                  ? const Column(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Preparing puzzles…',
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
