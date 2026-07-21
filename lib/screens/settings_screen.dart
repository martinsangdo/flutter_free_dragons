import 'package:flutter/material.dart';
import '../data/app_prefs.dart';
import '../data/level_repository.dart';
import '../data/progress_service.dart';
import '../data/sound_service.dart';
import '../theme/app_colors.dart';
import 'how_to_play_screen.dart';

/// Central place for persisted preferences: independent sound-effect and music
/// toggles, a way to replay the how-to-play walkthrough, and a progress reset.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sfx = SoundService.instance.sfxEnabled;
  bool _music = SoundService.instance.musicEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 8),
            _sectionLabel('AUDIO'),
            _switchTile(
              icon: Icons.graphic_eq,
              label: 'Sound Effects',
              value: _sfx,
              onChanged: (v) async {
                await SoundService.instance.setSfxEnabled(v);
                setState(() => _sfx = v);
                if (v) SoundService.instance.playMove();
              },
            ),
            _switchTile(
              icon: Icons.music_note,
              label: 'Background Music',
              value: _music,
              onChanged: (v) async {
                await SoundService.instance.setMusicEnabled(v);
                setState(() => _music = v);
              },
            ),
            const SizedBox(height: 16),
            _sectionLabel('HELP'),
            _actionTile(
              icon: Icons.help_outline,
              label: 'How to Play',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('DATA'),
            _actionTile(
              icon: Icons.restart_alt,
              label: 'Reset Progress',
              destructive: true,
              onTap: _confirmReset,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(
                child: Text(
                  'Free The Key • v1.0.0',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'SETTINGS',
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

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      );

  Widget _switchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gridLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16)),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFFF4488) : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.boardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gridLine),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: destructive ? color : AppColors.textPrimary,
                      fontSize: 16)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.boardBg,
        title: const Text('Reset Progress?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This clears every unlocked level, star and your endless best. This '
          'cannot be undone.',
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
            child: const Text('RESET',
                style: TextStyle(color: Color(0xFFFF4488))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ProgressService.resetProgress(LevelRepository.instance.levelCount);
      await AppPrefs.resetEndless();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset')),
        );
      }
    }
  }
}
