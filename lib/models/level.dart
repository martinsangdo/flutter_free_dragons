class BlockConfig {
  final int row;
  final int col;
  final int length;
  final bool isHorizontal;
  final bool isKey;

  const BlockConfig({
    required this.row,
    required this.col,
    required this.length,
    required this.isHorizontal,
    this.isKey = false,
  });
}

class Level {
  final int number;
  final String difficulty;
  final List<BlockConfig> blocks;
  final int par;

  const Level({
    required this.number,
    required this.difficulty,
    required this.blocks,
    required this.par,
  });
}
