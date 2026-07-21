import 'package:flutter/material.dart';
import '../data/app_prefs.dart';
import '../data/daily_service.dart';
import '../theme/app_colors.dart';
import 'level_select_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  DailyStatus? _daily;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    final status = await DailyService.status();
    if (mounted) setState(() => _daily = status);
  }

  Future<void> _openDaily() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GameScreen(mode: GameMode.daily),
      ),
    );
    _loadDaily(); // reflect any new completion/streak on return
  }

  /// Endless resumes where the player left off: [AppPrefs.getEndlessBest]
  /// stores the number of endless levels cleared, which is exactly the 0-based
  /// index of the next unplayed one.
  Future<void> _openEndless() async {
    final resumeIndex = await AppPrefs.getEndlessBest();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(index: resumeIndex, mode: GameMode.endless),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    _buildLogo(),
                    const SizedBox(height: 12),
                    const Text(
                      'Slide blocks. Free the key.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(flex: 3),
                    _buildDailyCard(),
                    const SizedBox(height: 14),
                    _buildButton('PLAY', Icons.play_arrow_rounded, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const GameScreen(index: 0)),
                      );
                    }, AppColors.primary, AppColors.buttonText),
                    const SizedBox(height: 14),
                    _buildButton('LEVELS', Icons.grid_view_rounded, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LevelSelectScreen()),
                      );
                    }, AppColors.boardBg, AppColors.primary),
                    const SizedBox(height: 14),
                    _buildButton('ENDLESS', Icons.all_inclusive_rounded,
                        _openEndless, AppColors.boardBg, AppColors.keyBlock),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.boardBg,
              border: Border.all(
                color: AppColors.keyBlock.withOpacity(0.4 + _pulse.value * 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.keyGlow.withOpacity(0.15 + _pulse.value * 0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: AppColors.keyBlock,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FREE THE KEY',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard() {
    final daily = _daily;
    final done = daily?.completedToday ?? false;
    final streak = daily?.streak ?? 0;

    return GestureDetector(
      onTap: _openDaily,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.boardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.keyGlow.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.keyGlow.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.today_rounded,
              color: done ? AppColors.exitGlow : AppColors.keyBlock,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY CHALLENGE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Done today — come back tomorrow' : 'New puzzle ready',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (streak > 0) _streakBadge(streak),
          ],
        ),
      ),
    );
  }

  Widget _streakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.keyGlow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.keyGlow, size: 18),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      String label, IconData icon, VoidCallback onTap, Color bg, Color fg) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fg.withOpacity(0.4)),
            boxShadow: bg == AppColors.primary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
