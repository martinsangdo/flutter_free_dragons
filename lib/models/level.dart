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

  Map<String, dynamic> toJson() => {
        'r': row,
        'c': col,
        'l': length,
        'h': isHorizontal,
        if (isKey) 'k': true,
      };

  factory BlockConfig.fromJson(Map<String, dynamic> j) => BlockConfig(
        row: j['r'] as int,
        col: j['c'] as int,
        length: j['l'] as int,
        isHorizontal: j['h'] as bool,
        isKey: j['k'] as bool? ?? false,
      );
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

  Map<String, dynamic> toJson() => {
        'n': number,
        'd': difficulty,
        'p': par,
        'b': blocks.map((b) => b.toJson()).toList(),
      };

  factory Level.fromJson(Map<String, dynamic> j) => Level(
        number: j['n'] as int,
        difficulty: j['d'] as String,
        par: j['p'] as int,
        blocks: (j['b'] as List)
            .map((e) => BlockConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
