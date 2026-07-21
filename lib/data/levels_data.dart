import '../models/level.dart';

// Grid is 6×6. Exit is right side of row 2.
// Horizontal block occupies (row, col)..(row, col+length-1)
// Vertical   block occupies (row, col)..(row+length-1, col)
//
// These 20 hand-authored levels form the tutorial-to-Expert curve and always
// appear first. The remaining campaign levels (to reach 80+) are generated and
// verified solvable by [LevelRepository]. See lib/logic/solver.dart.
const List<Level> kCuratedLevels = [
  // ── EASY ──────────────────────────────────────────────────────────────────
  Level(
    number: 1, difficulty: 'Easy', par: 2,
    blocks: [
      BlockConfig(row: 2, col: 2, length: 2, isHorizontal: true,  isKey: true),
      // A col4 rows1-2  →  move A up, slide key right
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 2, difficulty: 'Easy', par: 3,
    blocks: [
      BlockConfig(row: 2, col: 1, length: 2, isHorizontal: true,  isKey: true),
      // A col3 rows1-2,  B col4 rows1-2
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 3, difficulty: 'Easy', par: 4,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 4, difficulty: 'Easy', par: 3,
    blocks: [
      BlockConfig(row: 2, col: 1, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 vertical col3 rows0-2  →  B right, A down, key right
      BlockConfig(row: 0, col: 3, length: 3, isHorizontal: false),
      BlockConfig(row: 3, col: 3, length: 2, isHorizontal: true),
    ],
  ),
  Level(
    number: 5, difficulty: 'Easy', par: 4,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2, B row3 cols2-3 (blocks A down), C col4 rows1-2
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  // ── MEDIUM ────────────────────────────────────────────────────────────────
  Level(
    number: 6, difficulty: 'Medium', par: 4,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B row0 cols2-3 (blocks A up),
      // C row3 cols2-3 (blocks A down),  D col4 rows1-2
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 7, difficulty: 'Medium', par: 5,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 8, difficulty: 'Medium', par: 4,
    blocks: [
      BlockConfig(row: 2, col: 2, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col4 rows0-2,  B row3 cols4-5 (blocks A down),
      // C col2 rows3-4 (blocks B moving left)
      BlockConfig(row: 0, col: 4, length: 3, isHorizontal: false),
      BlockConfig(row: 3, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 9, difficulty: 'Medium', par: 5,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2,  B row3 cols2-3 (blocks A down),
      // C col3 rows1-2,  E col4 rows2-3
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 4, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 10, difficulty: 'Medium', par: 5,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B row0 cols2-3 (blocks A up),
      // C col3 rows1-2,  D col4 rows1-2,  E row0 cols4-5 (blocks D up)
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 4, length: 2, isHorizontal: true),
    ],
  ),
  // ── HARD ──────────────────────────────────────────────────────────────────
  Level(
    number: 11, difficulty: 'Hard', par: 6,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B row0 cols2-3,  C row3 cols2-3,
      // D col3 rows1-2,  F col4 rows1-2,  G col5 rows1-2
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 12, difficulty: 'Hard', par: 6,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2,  B row4 cols2-3 (blocks A down),
      // C col3 rows1-2,  D col4 rows1-2,  E col5 rows2-3
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 4, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 13, difficulty: 'Hard', par: 7,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2,  B row4 cols1-2 (blocks A going far down),
      // C col3 rows1-2,  D row0 cols3-4 (blocks C up),
      // E col4 rows1-2,  F col5 rows0-1,  G col5 rows2-3
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 4, col: 1, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 14, difficulty: 'Hard', par: 7,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B row0 cols2-3,  C row3 cols2-3,
      // D col3 rows1-2,  E row0 cols4-5,  F col4 rows1-2,
      // G col5 rows1-2,  H row4 cols4-5
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 4, length: 2, isHorizontal: true),
    ],
  ),
  Level(
    number: 15, difficulty: 'Hard', par: 6,
    blocks: [
      BlockConfig(row: 2, col: 1, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col3 rows0-2,  B row4 cols3-4 (blocks A down),
      // C col4 rows1-2,  G row0 cols4-5 (blocks C up),
      // E col5 rows2-3,  F col5 rows4-5 (blocks E down)
      BlockConfig(row: 0, col: 3, length: 3, isHorizontal: false),
      BlockConfig(row: 4, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  // ── EXPERT ────────────────────────────────────────────────────────────────
  Level(
    number: 16, difficulty: 'Expert', par: 7,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2,  B row4 cols2-3,  C row0 cols3-4,
      // D col3 rows1-2,  E col4 rows1-2,  F col5 rows0-1,  G col5 rows2-3
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 4, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 0, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 17, difficulty: 'Expert', par: 7,
    blocks: [
      BlockConfig(row: 2, col: 1, length: 2, isHorizontal: true,  isKey: true),
      // A col3 rows1-2,  B row0 cols3-4,  C row3 cols3-4,
      // D col4 rows1-2,  E col5 rows0-1,  F col5 rows2-3,  G row4 cols3-4
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 3, length: 2, isHorizontal: true),
    ],
  ),
  Level(
    number: 18, difficulty: 'Expert', par: 8,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B len-3 row0 cols1-3,  C row3 cols2-3,
      // D col3 rows1-2,  E col4 rows1-2,  F row0 cols4-5,
      // G col5 rows2-3,  H row4 cols4-5
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 1, length: 3, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 4, length: 2, isHorizontal: true),
    ],
  ),
  Level(
    number: 19, difficulty: 'Expert', par: 8,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A len-3 col2 rows0-2,  B row4 cols2-3,  C col3 rows1-2,
      // D row0 cols3-4,  E col4 rows1-2,  F col5 rows2-3,  G col5 rows4-5
      BlockConfig(row: 0, col: 2, length: 3, isHorizontal: false),
      BlockConfig(row: 4, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 3, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 2, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 5, length: 2, isHorizontal: false),
    ],
  ),
  Level(
    number: 20, difficulty: 'Expert', par: 9,
    blocks: [
      BlockConfig(row: 2, col: 0, length: 2, isHorizontal: true,  isKey: true),
      // A col2 rows1-2,  B row0 cols2-3,  C row3 cols2-3,
      // D col3 rows1-2,  E row0 cols4-5,  F col4 rows1-2,
      // G row3 cols4-5,  H col5 rows1-2,  I col5 rows4-5
      BlockConfig(row: 1, col: 2, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 3, col: 2, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 3, length: 2, isHorizontal: false),
      BlockConfig(row: 0, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 4, length: 2, isHorizontal: false),
      BlockConfig(row: 3, col: 4, length: 2, isHorizontal: true),
      BlockConfig(row: 1, col: 5, length: 2, isHorizontal: false),
      BlockConfig(row: 4, col: 5, length: 2, isHorizontal: false),
    ],
  ),
];
