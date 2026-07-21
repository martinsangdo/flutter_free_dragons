import 'package:flutter/material.dart';
import '../data/app_prefs.dart';
import '../data/egg_sprites.dart';
import '../models/block.dart';
import '../theme/app_colors.dart';
import '../widgets/board_painter.dart';
import 'home_screen.dart';

/// Explains the core rules with illustrated pages. Shown automatically on the
/// very first launch (with [firstLaunch] = true, which persists the "seen" flag
/// and continues to Home), and re-openable later from Settings.
class HowToPlayScreen extends StatefulWidget {
  final bool firstLaunch;
  const HowToPlayScreen({super.key, this.firstLaunch = false});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _HowToPage(
      title: 'FREE THE EGGS',
      body: 'Slide the glowing golden egg off the right edge of the '
          'board to win each level.',
      blocks: [
        _Demo(2, 1, 2, true, key: true),
        _Demo(1, 4, 2, false),
      ],
    ),
    _HowToPage(
      title: 'SLIDE THE BLOCKS',
      body: 'Drag a block along its lane. Wide blocks move left and right; '
          'tall blocks move up and down. They never turn.',
      blocks: [
        _Demo(2, 0, 2, true, key: true),
        _Demo(0, 3, 3, false),
        _Demo(4, 1, 2, true),
      ],
    ),
    _HowToPage(
      title: 'CLEAR THE PATH',
      body: 'Blockers stand between the egg and the exit. Shuffle them out of '
          'the way to open a lane.',
      blocks: [
        _Demo(2, 0, 2, true, key: true),
        _Demo(1, 3, 2, false),
        _Demo(0, 4, 2, false),
        _Demo(3, 4, 2, false),
      ],
    ),
    _HowToPage(
      title: 'FEWER MOVES, MORE STARS',
      body: 'Beat the par move count for 3 stars. Stuck? Tap the Hint button '
          'in a level to reveal the next best move.',
      blocks: [
        _Demo(2, 2, 2, true, key: true),
        _Demo(1, 4, 2, false),
      ],
    ),
  ];

  Future<void> _finish() async {
    if (widget.firstLaunch) {
      await AppPrefs.setHowToPlaySeen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  widget.firstLaunch ? 'SKIP' : 'CLOSE',
                  style: const TextStyle(
                      color: AppColors.textSecondary, letterSpacing: 1.5),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            _buildDots(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isLast ? 'PLAY' : 'NEXT',
                      style: const TextStyle(
                        color: AppColors.buttonText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Lightweight spec for a demo block used only in the tutorial illustrations.
class _Demo {
  final int row, col, length;
  final bool horizontal;
  final bool key;
  const _Demo(this.row, this.col, this.length, this.horizontal,
      {this.key = false});
}

class _HowToPage extends StatelessWidget {
  final String title;
  final String body;
  final List<_Demo> blocks;
  const _HowToPage({
    required this.title,
    required this.body,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBoard(),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    const size = 240.0;
    const cell = size / 6;
    final demoBlocks = <Block>[];
    int id = 0;
    int colorIdx = 0;
    for (final d in blocks) {
      demoBlocks.add(Block(
        id: id++,
        row: d.row,
        col: d.col,
        length: d.length,
        isHorizontal: d.horizontal,
        isKey: d.key,
        color: d.key
            ? AppColors.keyBlock
            : AppColors.blockColors[colorIdx++ % AppColors.blockColors.length],
      ));
    }
    return SizedBox(
      width: size + 24,
      height: size,
      child: CustomPaint(
        painter: BoardPainter(
          blocks: demoBlocks,
          cellSize: cell,
          exitPulse: 1,
          eggSprite: EggSprites.sample,
        ),
      ),
    );
  }
}
