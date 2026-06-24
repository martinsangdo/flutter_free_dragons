import 'package:flutter/material.dart';
import '../data/levels_data.dart';
import '../data/progress_service.dart';
import '../theme/app_colors.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _highestUnlocked = 0;
  Map<int, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final h = await ProgressService.getHighestUnlocked();
    final s = await ProgressService.getAllStars(kLevels.length);
    if (mounted) setState(() {
      _highestUnlocked = h;
      _stars = s;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'SELECT LEVEL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final groups = <String, List<int>>{};
    for (int i = 0; i < kLevels.length; i++) {
      final d = kLevels[i].difficulty;
      groups.putIfAbsent(d, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: groups.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10),
              child: Text(
                e.key.toUpperCase(),
                style: TextStyle(
                  color: _difficultyColor(e.key),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: e.value
                  .map((idx) => _levelCard(context, idx))
                  .toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _levelCard(BuildContext context, int idx) {
    final level = kLevels[idx];
    final unlocked = ProgressService.isUnlocked(idx, _highestUnlocked);
    final completed = _stars.containsKey(idx);
    final starCount = _stars[idx] ?? 0;
    final color = _difficultyColor(level.difficulty);

    return GestureDetector(
      onTap: unlocked
          ? () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameScreen(levelIndex: idx)),
              );
              _loadProgress();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? AppColors.boardBg : AppColors.boardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? color.withOpacity(0.4)
                : AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${level.number}',
              style: TextStyle(
                color: unlocked ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.4),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                  i < starCount ? Icons.star : Icons.star_border,
                  size: 10,
                  color: i < starCount ? AppColors.starActive : AppColors.starInactive,
                )),
              )
            else
              Icon(
                unlocked ? Icons.lock_open : Icons.lock,
                color: unlocked
                    ? color.withOpacity(0.7)
                    : AppColors.textSecondary.withOpacity(0.3),
                size: 14,
              ),
          ],
        ),
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
