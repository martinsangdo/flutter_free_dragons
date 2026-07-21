import '../data/constants.dart';
import '../models/level.dart';

/// A single block move discovered by the solver: [blockIndex] refers to the
/// index of the block in the level's `blocks` list (which equals the runtime
/// `Block.id` assigned by [GameEngine]). [delta] is the signed number of cells
/// (positive = right/down, negative = left/up).
class SolverMove {
  final int blockIndex;
  final int delta;
  const SolverMove(this.blockIndex, this.delta);
}

/// Result of analysing a board.
class SolveResult {
  final bool solvable;

  /// Minimum number of *game moves* (single-cell steps of non-key blocks)
  /// required to free the key. `-1` when unsolvable.
  final int minMoves;

  /// An optimal sequence of block moves, empty when unsolvable.
  final List<SolverMove> path;

  const SolveResult(this.solvable, this.minMoves, this.path);

  static const unsolvable = SolveResult(false, -1, []);
}

/// A breadth-first / Dijkstra solver for the "Free The Eggs" (Rush Hour style)
/// board. It is used both to verify hand-authored levels and to reject
/// unsolvable procedurally-generated boards before they ever reach a player.
///
/// The cost model matches the live game exactly: sliding a non-key block by one
/// cell counts as one move, key-block movement is free. This guarantees the
/// computed `par` is actually reachable in-game.
class RushHourSolver {
  final int gridSize;
  final int exitRow;

  // Per-block immutable data (parallel arrays for speed).
  final List<bool> _isHorizontal;
  final List<bool> _isKey;
  final List<int> _len;
  final List<int> _fixed; // row for horizontal blocks, col for vertical blocks
  final int _n;
  final int _keyIndex;

  RushHourSolver._(
    this.gridSize,
    this.exitRow,
    this._isHorizontal,
    this._isKey,
    this._len,
    this._fixed,
    this._n,
    this._keyIndex,
  );

  factory RushHourSolver(List<BlockConfig> blocks,
      {int gridSize = kGridSize, int exitRow = kExitRow}) {
    final isH = <bool>[];
    final isK = <bool>[];
    final len = <int>[];
    final fixed = <int>[];
    int keyIndex = -1;
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      isH.add(b.isHorizontal);
      isK.add(b.isKey);
      len.add(b.length);
      fixed.add(b.isHorizontal ? b.row : b.col);
      if (b.isKey) keyIndex = i;
    }
    return RushHourSolver._(
        gridSize, exitRow, isH, isK, len, fixed, blocks.length, keyIndex);
  }

  /// The variable coordinate of each block in its starting position
  /// (col for horizontal blocks, row for vertical blocks).
  List<int> _initialState(List<BlockConfig> blocks) => [
        for (final b in blocks) b.isHorizontal ? b.col : b.row,
      ];

  /// Pack a state (list of var-positions, each 0..gridSize-1) into a single int.
  /// 3 bits per block supports grids up to size 8, and up to 21 blocks in 63
  /// bits — far more than any real board uses.
  int _encode(List<int> pos) {
    int key = 0;
    for (int i = 0; i < _n; i++) {
      key |= (pos[i] & 0x7) << (3 * i);
    }
    return key;
  }

  List<int> _decode(int key) {
    final pos = List<int>.filled(_n, 0);
    for (int i = 0; i < _n; i++) {
      pos[i] = (key >> (3 * i)) & 0x7;
    }
    return pos;
  }

  /// Build a gridSize×gridSize occupancy map (block index per cell, or -1),
  /// optionally excluding one block.
  List<int> _occupancy(List<int> pos, {int exclude = -1}) {
    final grid = List<int>.filled(gridSize * gridSize, -1);
    for (int i = 0; i < _n; i++) {
      if (i == exclude) continue;
      final p = pos[i];
      for (int c = 0; c < _len[i]; c++) {
        final r = _isHorizontal[i] ? _fixed[i] : p + c;
        final col = _isHorizontal[i] ? p + c : _fixed[i];
        grid[r * gridSize + col] = i;
      }
    }
    return grid;
  }

  /// True when the key can slide off the right edge from this state, i.e. every
  /// cell to its right on the exit row is empty.
  bool _isWin(List<int> pos, List<int> grid) {
    final keyCol = pos[_keyIndex];
    final rightEdge = keyCol + _len[_keyIndex];
    for (int c = rightEdge; c < gridSize; c++) {
      if (grid[exitRow * gridSize + c] != -1) return false;
    }
    return true;
  }

  /// Verify solvability and compute the optimal par. Runs a Dijkstra search
  /// because key moves are free (cost 0) while other moves cost their cell
  /// distance.
  SolveResult solve(List<BlockConfig> blocks) {
    final start = _encode(_initialState(blocks));

    // dist + predecessor for path reconstruction.
    final dist = <int, int>{start: 0};
    final prev = <int, int>{}; // stateKey -> parentKey
    final prevMove = <int, SolverMove>{};

    // Simple binary min-heap of (cost, stateKey).
    final heap = _MinHeap();
    heap.push(0, start);

    int explored = 0;
    const explorationCap = 2000000;

    while (!heap.isEmpty) {
      final (cost, key) = heap.pop();
      if (cost > (dist[key] ?? 1 << 62)) continue; // stale entry
      if (++explored > explorationCap) return SolveResult.unsolvable;

      final pos = _decode(key);
      final grid = _occupancy(pos);

      if (_isWin(pos, grid)) {
        return SolveResult(true, cost, _reconstruct(prev, prevMove, key, start));
      }

      // Expand: for each block, every reachable stop in both directions.
      for (int i = 0; i < _n; i++) {
        final p = pos[i];
        final horizontal = _isHorizontal[i];
        final fixed = _fixed[i];
        final moveCost = _isKey[i] ? 0 : 1;

        // Forward (right/down).
        for (int d = 1; d < gridSize; d++) {
          final leadVar = p + _len[i] - 1 + d;
          if (leadVar >= gridSize) break;
          final r = horizontal ? fixed : leadVar;
          final c = horizontal ? leadVar : fixed;
          if (grid[r * gridSize + c] != -1) break;
          _relax(pos, i, d, moveCost * d, key, cost, dist, prev, prevMove, heap);
        }
        // Backward (left/up).
        for (int d = 1; d <= p; d++) {
          final tailVar = p - d;
          final r = horizontal ? fixed : tailVar;
          final c = horizontal ? tailVar : fixed;
          if (grid[r * gridSize + c] != -1) break;
          _relax(
              pos, i, -d, moveCost * d, key, cost, dist, prev, prevMove, heap);
        }
      }
    }
    return SolveResult.unsolvable;
  }

  void _relax(
    List<int> pos,
    int block,
    int delta,
    int edgeCost,
    int fromKey,
    int fromCost,
    Map<int, int> dist,
    Map<int, int> prev,
    Map<int, SolverMove> prevMove,
    _MinHeap heap,
  ) {
    final np = List<int>.of(pos);
    np[block] += delta;
    final nk = _encode(np);
    final nc = fromCost + edgeCost;
    if (nc < (dist[nk] ?? 1 << 62)) {
      dist[nk] = nc;
      prev[nk] = fromKey;
      prevMove[nk] = SolverMove(block, delta);
      heap.push(nc, nk);
    }
  }

  List<SolverMove> _reconstruct(
      Map<int, int> prev, Map<int, SolverMove> prevMove, int end, int start) {
    final moves = <SolverMove>[];
    int cur = end;
    while (cur != start && prevMove.containsKey(cur)) {
      moves.add(prevMove[cur]!);
      cur = prev[cur]!;
    }
    return moves.reversed.toList();
  }

  /// Convenience: is this level solvable at all?
  bool isSolvable(List<BlockConfig> blocks) => solve(blocks).solvable;
}

/// Tiny binary min-heap keyed on int cost; avoids a package:collection import.
class _MinHeap {
  final List<int> _cost = [];
  final List<int> _val = [];

  bool get isEmpty => _cost.isEmpty;

  void push(int cost, int val) {
    _cost.add(cost);
    _val.add(val);
    int i = _cost.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_cost[parent] <= _cost[i]) break;
      _swap(i, parent);
      i = parent;
    }
  }

  (int, int) pop() {
    final cost = _cost[0];
    final val = _val[0];
    final last = _cost.length - 1;
    _cost[0] = _cost[last];
    _val[0] = _val[last];
    _cost.removeLast();
    _val.removeLast();
    int i = 0;
    final n = _cost.length;
    while (true) {
      final l = 2 * i + 1, r = 2 * i + 2;
      int smallest = i;
      if (l < n && _cost[l] < _cost[smallest]) smallest = l;
      if (r < n && _cost[r] < _cost[smallest]) smallest = r;
      if (smallest == i) break;
      _swap(i, smallest);
      i = smallest;
    }
    return (cost, val);
  }

  void _swap(int a, int b) {
    final tc = _cost[a];
    _cost[a] = _cost[b];
    _cost[b] = tc;
    final tv = _val[a];
    _val[a] = _val[b];
    _val[b] = tv;
  }
}
