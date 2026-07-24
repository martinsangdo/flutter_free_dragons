import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D1B2A);
  static const Color boardBg = Color(0xFF1B2A4A);
  static const Color gridLine = Color(0xFF2A3F6A);
  static const Color primary = Color(0xFF00D4FF);
  static const Color keyBlock = Color(0xFFFFD700);
  static const Color keyGlow = Color(0xFFFF8C00);
  static const Color exitGlow = Color(0xFF00FF88);
  static const Color textPrimary = Color(0xFFE8F4F8);
  static const Color textSecondary = Color(0xFF8AAABB);
  static const Color starActive = Color(0xFFFFD700);
  static const Color starInactive = Color(0xFF3A4A5A);
  static const Color buttonPrimary = Color(0xFF00D4FF);
  static const Color buttonText = Color(0xFF0D1B2A);
  static const Color completedLevel = Color(0xFF00C878);
  static const Color lockedLevel = Color(0xFF3A4A5A);
  static const Color shadow = Color(0x88000000);

  /// Mortar between the bricks of an obstacle block.
  static const Color mortar = Color(0xFF6B5F55);

  // --- Ancient Temple / Relic Vault theme (board rendering only) ---
  /// Warm torch light — used for the board vignette, engraved runes and rims.
  static const Color torchGlow = Color(0xFFFFB067);

  /// Carved stone slab the board is cut from (top of the slab gradient).
  static const Color templeFloor = Color(0xFF262130);

  /// Bottom of the slab gradient — deeper in shadow.
  static const Color templeFloorDeep = Color(0xFF15111C);

  /// Recessed socket each block rests in, cut into the slab.
  static const Color templeSlot = Color(0xFF191521);

  /// Obstacle blocks are drawn as brick walls, so these are clay/stone tones
  /// rather than neon. They stay varied enough that adjacent blocks read as
  /// separate pieces, but none of them competes with the golden egg.
  static const List<Color> blockColors = [
    Color(0xFF9E4B34), // terracotta
    Color(0xFF7D3B2B), // deep clay
    Color(0xFFB35F3F), // rust
    Color(0xFF8A5A44), // umber
    Color(0xFF6E4636), // dark brick
    Color(0xFFA8603C), // sienna
    Color(0xFF7A5548), // taupe brick
    Color(0xFF95503A), // burnt clay
    Color(0xFF66463A), // shadow brick
    Color(0xFFAD6A4A), // sandstone
  ];
}
