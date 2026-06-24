import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/level.dart';
import '../theme/app_colors.dart';
import '../widgets/game_board.dart';
import '../data/levels_data.dart';
import '../data/progress_service.dart';
import '../data/sound_service.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;

  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late GameEngine _engine;
  late AnimationController _winController;
  late Animation<double> _winScale;
  late AnimationController _bgController;
  bool _showWin = false;
  bool _muted = false;

  Level get _level => kLevels[widget.levelIndex];

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(_level);
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winScale = CurvedAnimation(parent: _winController, curve: Curves.elasticOut);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _muted = SoundService.instance.isMuted;
  }

  @override
  void dispose() {
    _engine.dispose();
    _winController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onWin() {
    ProgressService.markCompleted(widget.levelIndex, _engine.starRating);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _showWin = true);
      _winController.forward(from: 0);
    });
  }

  Future<void> _toggleSound() async {
    await SoundService.instance.toggleMute();
    setState(() => _muted = SoundService.instance.isMuted);
  }

  void _reset() {
    _engine.reset();
    setState(() => _showWin = false);
    _winController.reset();
  }

  void _nextLevel() {
    final nextIdx = widget.levelIndex + 1;
    if (nextIdx >= kLevels.length) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(levelIndex: nextIdx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              painter: _BackgroundPainter(_bgController.value),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                _buildGame(),
                if (_showWin) _buildWinOverlay(),
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
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GameBoard(
                engine: _engine,
                onWin: _onWin,
                onMove: () => SoundService.instance.play(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'LEVEL ${_level.number}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
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
          IconButton(
            icon: Icon(
              _muted ? Icons.volume_off : Icons.volume_up,
              color: AppColors.textSecondary,
            ),
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
                  color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
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
                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
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
                  const Icon(Icons.lock_open, color: AppColors.keyBlock, size: 56),
                  const SizedBox(height: 12),
                  const Text('KEY FREED!',
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
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _winButton('RETRY', _reset,
                            AppColors.boardBg, AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      if (widget.levelIndex + 1 < kLevels.length)
                        Expanded(
                          child: _winButton('NEXT', _nextLevel,
                              AppColors.primary, AppColors.buttonText),
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
                color: fg, fontSize: 15, fontWeight: FontWeight.bold,
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
    // Base fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    // Animated orbs: (x%, y%, radius%, color, phase offset)
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

    // Subtle grid-dot pattern
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
