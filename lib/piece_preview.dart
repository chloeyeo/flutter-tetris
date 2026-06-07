import 'package:flutter/material.dart';
import 'values.dart';
import 'skins.dart';

class PiecePreview extends StatelessWidget {
  final Tetromino? type;
  final TetrisSkin skin;

  const PiecePreview({
    super.key,
    required this.type,
    required this.skin,
  });

  @override
  Widget build(BuildContext context) {
    if (type == null) return const SizedBox();

    // Get the grid positions for each shape
    // Relative to a 4x4 grid center
    final List<List<int>> shapeCoords = _getShapeCoords(type!);

    return LayoutBuilder(
      builder: (context, constraints) {
        double boxSize = constraints.maxWidth;
        double cellSize = boxSize / 4;

        return Stack(
          children: shapeCoords.map((coord) {
            return Positioned(
              left: coord[0] * cellSize,
              top: coord[1] * cellSize,
              child: Container(
                width: cellSize - 1,
                height: cellSize - 1,
                decoration: BoxDecoration(
                  color: skin.colors[type] ?? Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: skin.emojis?[type] != null
                    ? Center(
                        child: Text(
                          skin.emojis![type]!,
                          style: TextStyle(fontSize: cellSize * 0.6),
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<List<int>> _getShapeCoords(Tetromino type) {
    switch (type) {
      case Tetromino.L:
        return [[1, 1], [1, 2], [1, 3], [2, 3]];
      case Tetromino.J:
        return [[2, 1], [2, 2], [2, 3], [1, 3]];
      case Tetromino.I:
        return [[1, 0], [1, 1], [1, 2], [1, 3]];
      case Tetromino.O:
        return [[1, 1], [2, 1], [1, 2], [2, 2]];
      case Tetromino.S:
        return [[1, 2], [2, 2], [2, 1], [3, 1]];
      case Tetromino.Z:
        return [[1, 1], [2, 1], [2, 2], [3, 2]];
      case Tetromino.T:
        return [[1, 1], [2, 1], [3, 1], [2, 2]];
    }
  }
}
