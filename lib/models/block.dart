import 'package:flutter/material.dart';

class Block {
  final int id;
  int row;
  int col;
  final int length;
  final bool isHorizontal;
  final bool isKey;
  final Color color;

  Block({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.isHorizontal,
    this.isKey = false,
    required this.color,
  });

  List<(int, int)> get cells {
    return List.generate(length, (i) {
      return isHorizontal ? (row, col + i) : (row + i, col);
    });
  }

  Block clone() => Block(
        id: id,
        row: row,
        col: col,
        length: length,
        isHorizontal: isHorizontal,
        isKey: isKey,
        color: color,
      );
}
