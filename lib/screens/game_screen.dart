import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/level.dart';
import '../theme/app_colors.dart';
import '../widgets/game_board.dart';
import '../widgets/banner_ad_placeholder.dart';
import '../data/level_repository.dart';
import '../data/app_prefs.dart';
import '../data/daily_service.dart';
import '../data/progress_service.dart';
import '../data/sound_service.dart';

enum GameMode { campaign, endless, daily }

/// Plays a single level in one of three modes:
///  - [GameMode.campaign]: [index] is the level index (0-based).
///  - [GameMode.endless]:  [index] is the 0-based endless level number.
///  - [GameMode.daily]:    today's deterministic daily challenge.
class GameScreen extends StatefulWidget {
  final int index;
  final GameMode mode;

  const GameScreen({super.key, this.index = 0, this.mode = GameMode.campaign});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _engine;
  late Level _level;
  late AnimationController _winController;
  late Animation<double> _winScale;
  late AnimationController _bgController;
  bool _showWin = false;
  bool _sfxOn = false;
  int _dailyStreak = 0;

  bool get _isEndless => widget.mode == GameMode.endless;
  bool get _isDaily => widget.mode == GameMode.daily;

  @override
  void initState() {
    super.initState();
    final repo = LevelRepository.instance;
    switch (widget.mode) {
      case GameMode.campaign:
        _level = repo.levels[widget.index];
        break;
      case GameMode.endless:
        _level = repo.endlessLevel(widget.index);
        break;
      case GameMode.daily:
        _level = repo.dailyLevel(DateTime.now());
        break;
    }
    _engine = GameEngine(_level);
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winScale =
        CurvedAnimation(parent: _winController, curve: Curves.elasticOut);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _sfxOn = SoundService.instance.sfxEnabled;
  }

  @override
  void dispose() {
    _engine.dispose();
    _winController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _onWin() async {
    switch (widget.mode) {
      case GameMode.campaign:
        ProgressService.markCompleted(widget.index, _engine.starRating);
        break;
      case GameMode.endless:
        // Reaching level N means N levels cleared.
        await AppPrefs.recordEndless(widget.index + 1);
        break;
      case GameMode.daily:
        final result = await DailyService.markComplete();
        _dailyStreak = result.streak;
        break;
    }
    SoundService.instance.playWin();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _showWin = true);
      _winController.forward(from: 0);
    });
  }

  Future<void> _toggleSound() async {
    await SoundService.instance.setSfxEnabled(!_sfxOn);
    setState(() => _sfxOn = SoundService.instance.sfxEnabled);
  }

  void _reset() {
    _engine.reset();
    setState(() => _showWin = false);
    _winController.reset();
  }

  void _next() {
    final nextIdx = widget.index + 1;
    if (widget.mode == GameMode.campaign &&
        nextIdx >= LevelRepository.instance.levelCount) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(index: nextIdx, mode: widget.mode),
      ),
    );
  }

  /// Stubbed rewarded-ad hint flow. Wire a real rewarded ad in place of the
  /// dialog's "Watch" branch; on reward, [GameEngine.computeHint] already
  /// highlights the next optimal move (computed by the solver).
  Future<void> _showHint() async {
    if (_engine.isWon) return;
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.boardBg,
        title: const Text('Need a hint?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Watch a short video to reveal the next best move.\n\n'
          '(Rewarded ad placeholder — no ad SDK wired up yet.)',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('WATCH',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (watch == true) {
      final ok = _engine.computeHint();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hint available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _BackgroundPainter(_bgController.value),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      _buildGame(),
                      if (_showWin) _buildWinOverlay(),
                    ],
                  ),
                ),
                const BannerAdPlaceholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildStatsRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GameBoard(
                engine: _engine,
                onWin: _onWin,
                onMove: () => SoundService.instance.playMove(),
                eggSeed: _level.number,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _isDaily
                      ? 'DAILY CHALLENGE'
                      : _isEndless
                          ? 'ENDLESS #${widget.index + 1}'
                          : 'LEVEL ${_level.number}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  _level.difficulty.toUpperCase(),
                  style: TextStyle(
                    color: _difficultyColor(_level.difficulty),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Hint button — top-right, per spec.
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: AppColors.keyBlock),
            tooltip: 'Hint',
            onPressed: _showHint,
          ),
          IconButton(
            icon: Icon(_sfxOn ? Icons.volume_up : Icons.volume_off,
                color: AppColors.textSecondary),
            onPressed: _toggleSound,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _engine,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statCard('MOVES', '${_engine.moves}', AppColors.primary),
            _statCard('PAR', '${_level.par}', AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
    final hasNext = _isEndless ||
        (widget.mode == GameMode.campaign &&
            widget.index + 1 < LevelRepository.instance.levelCount);
    return AnimatedBuilder(
      animation: _winScale,
      builder: (_, __) => Container(
        color: Colors.black54,
        child: Center(
          child: Transform.scale(
            scale: _winScale.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.boardBg,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.egg_alt_rounded,
                      color: AppColors.keyBlock, size: 56),
                  const SizedBox(height: 12),
                  const Text('EGG FREED!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      )),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _engine,
                    builder: (_, __) => _buildStars(_engine.starRating),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _engine,
                    builder: (_, __) => Text(
                      '${_engine.moves} moves  •  par ${_level.par}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                  if (_isDaily) ...[
                    const SizedBox(height: 18),
                    _buildStreakBadge(),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _winButton('RETRY', _reset, AppColors.boardBg,
                            AppColors.textSecondary),
                      ),
                      if (hasNext) const SizedBox(width: 12),
                      if (hasNext)
                        Expanded(
                          child: _winButton('NEXT', _next, AppColors.primary,
                              AppColors.buttonText),
                        ),
                      if (_isDaily) const SizedBox(width: 12),
                      if (_isDaily)
                        Expanded(
                          child: _winButton(
                              'DONE',
                              () => Navigator.of(context).pop(),
                              AppColors.primary,
                              AppColors.buttonText),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    final unit = _dailyStreak == 1 ? 'day' : 'days';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.keyGlow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.keyGlow.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.keyGlow, size: 24),
          const SizedBox(width: 8),
          Text(
            '$_dailyStreak $unit streak',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < count ? Icons.star : Icons.star_border,
            color: i < count ? AppColors.starActive : AppColors.starInactive,
            size: 36,
          ),
        );
      }),
    );
  }

  Widget _winButton(String label, VoidCallback onTap, Color bg, Color fg) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return AppColors.completedLevel;
      case 'Medium':
        return AppColors.primary;
      case 'Hard':
        return AppColors.keyGlow;
      case 'Expert':
        return const Color(0xFFFF4488);
      case 'Master':
        return const Color(0xFFAA44FF);
      default:
        return AppColors.textSecondary;
    }
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    final orbs = [
      (0.15, 0.20, 0.45, AppColors.primary, 0.0),
      (0.85, 0.15, 0.38, AppColors.keyGlow, 0.33),
      (0.50, 0.78, 0.42, const Color(0xFFAA44FF), 0.66),
    ];

    for (final (fx, fy, fr, color, phase) in orbs) {
      final angle = (t + phase) * 2 * math.pi;
      final dx = size.width * 0.06 * math.sin(angle);
      final dy = size.height * 0.05 * math.cos(angle);
      final center = Offset(size.width * fx + dx, size.height * fy + dy);
      final radius = size.shortestSide * fr;
      final pulse = 0.85 + 0.15 * math.sin(angle * 1.5);

      canvas.drawCircle(
        center,
        radius * pulse,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withOpacity(0.18),
              color.withOpacity(0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius * pulse)),
      );
    }

    final dotPaint = Paint()..color = AppColors.primary.withOpacity(0.04);
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}
