import 'dart:ui';
import 'values.dart';

class Piece {
  Tetromino type;

  Piece({required this.type});

  List<int> position = [];

  Color get color {
    return tetrominoColors[type] ?? const Color(0xFFFFFFFF);
  }

  void initializePiece() {
    switch (type) {
      case Tetromino.L:
        position = [4, 14, 24, 25]; // Shifted from negative to visible range
        break;
      case Tetromino.J:
        position = [5, 15, 25, 24];
        break;
      case Tetromino.I:
        position = [4, 14, 24, 34];
        break;
      case Tetromino.O:
        position = [4, 5, 14, 15];
        break;
      case Tetromino.S:
        position = [15, 16, 24, 25];
        break;
      case Tetromino.Z:
        position = [14, 15, 25, 26];
        break;
      case Tetromino.T:
        position = [4, 14, 15, 24];
        break;
    }
  }

  void movePiece(Direction direction) {
    switch (direction) {
      case Direction.down:
        for (int i = 0; i < position.length; i++) {
          position[i] += rowLength;
        }
        break;
      case Direction.left:
        for (int i = 0; i < position.length; i++) {
          position[i] -= 1;
        }
        break;
      case Direction.right:
        for (int i = 0; i < position.length; i++) {
          position[i] += 1;
        }
        break;
    }
  }

  // rotation state
  int rotationState = 0;

  void rotatePiece(List<List<Tetromino?>> gameBoard) {
    List<int> newPosition = [];
    int nextRotationState = (rotationState + 1) % 4;

    switch (type) {
      case Tetromino.L:
        switch (nextRotationState) {
          case 0:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] + rowLength,
              position[1] + rowLength + 1,
            ];
            break;
          case 1:
            newPosition = [
              position[1] - 1,
              position[1],
              position[1] + 1,
              position[1] + rowLength - 1,
            ];
            break;
          case 2:
            newPosition = [
              position[1] + rowLength,
              position[1],
              position[1] - rowLength,
              position[1] - rowLength - 1,
            ];
            break;
          case 3:
            newPosition = [
              position[1] + 1,
              position[1],
              position[1] - 1,
              position[1] - rowLength + 1,
            ];
            break;
        }
        break;
      case Tetromino.J:
        switch (nextRotationState) {
          case 0:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] + rowLength,
              position[1] + rowLength - 1,
            ];
            break;
          case 1:
            newPosition = [
              position[1] - 1,
              position[1],
              position[1] + 1,
              position[1] - rowLength - 1,
            ];
            break;
          case 2:
            newPosition = [
              position[1] + rowLength,
              position[1],
              position[1] - rowLength,
              position[1] - rowLength + 1,
            ];
            break;
          case 3:
            newPosition = [
              position[1] + 1,
              position[1],
              position[1] - 1,
              position[1] + rowLength + 1,
            ];
            break;
        }
        break;
      case Tetromino.I:
        switch (nextRotationState) {
          case 0:
          case 2:
            newPosition = [
              position[1] - 1,
              position[1],
              position[1] + 1,
              position[1] + 2,
            ];
            break;
          case 1:
          case 3:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] + rowLength,
              position[1] + 2 * rowLength,
            ];
            break;
        }
        break;
      case Tetromino.O:
        newPosition = position;
        break;
      case Tetromino.S:
        switch (nextRotationState) {
          case 0:
          case 2:
            newPosition = [
              position[1],
              position[1] + 1,
              position[1] + rowLength - 1,
              position[1] + rowLength,
            ];
            break;
          case 1:
          case 3:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] + 1,
              position[1] + rowLength + 1,
            ];
            break;
        }
        break;
      case Tetromino.Z:
        switch (nextRotationState) {
          case 0:
          case 2:
            newPosition = [
              position[1],
              position[1] - 1,
              position[1] + rowLength,
              position[1] + rowLength + 1,
            ];
            break;
          case 1:
          case 3:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] - 1,
              position[1] + rowLength - 1,
            ];
            break;
        }
        break;
      case Tetromino.T:
        switch (nextRotationState) {
          case 0:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] + 1,
              position[1] + rowLength,
            ];
            break;
          case 1:
            newPosition = [
              position[1] - 1,
              position[1],
              position[1] + 1,
              position[1] + rowLength,
            ];
            break;
          case 2:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] - 1,
              position[1] + rowLength,
            ];
            break;
          case 3:
            newPosition = [
              position[1] - rowLength,
              position[1],
              position[1] - 1,
              position[1] + 1,
            ];
            break;
        }
        break;
    }

    // Attempt to rotate
    if (piecePositionIsValid(newPosition, gameBoard)) {
      position = newPosition;
      rotationState = nextRotationState;
    } else {
      // BETTER WALL KICK (SRS-lite)
      // Try shifting left, right, up
      List<int> kickOffsets = [
        1, -1, // Right, Left
        rowLength, // Down (actually push up if we check negative rowLength, but wait)
        -rowLength, // Up
        2, -2, // Far Right, Far Left
      ];
      
      for (int offset in kickOffsets) {
        List<int> kickedPosition = newPosition.map((pos) => pos + offset).toList();
        if (piecePositionIsValid(kickedPosition, gameBoard)) {
          position = kickedPosition;
          rotationState = nextRotationState;
          return;
        }
      }
    }
  }

  // check if valid position
  bool positionIsValid(int position, List<List<Tetromino?>> gameBoard) {
    int row = (position / rowLength).floor();
    int col = position % rowLength;

    // Out of bounds (bottom or sides)
    if (row >= colLength || col < 0 || col >= rowLength) {
      return false;
    }

    // Check if the spot is already taken on the board
    if (row >= 0 && gameBoard[row][col] != null) {
      return false;
    }

    return true;
  }

  // check if piece is valid position
  bool piecePositionIsValid(List<int> piecePosition, List<List<Tetromino?>> gameBoard) {
    bool firstColOccupied = false;
    bool lastColOccupied = false;

    for (int pos in piecePosition) {
      // return false if any position is already taken or out of bounds
      if (!positionIsValid(pos, gameBoard)) {
        return false;
      }

      int col = pos % rowLength;
      if (col == 0) firstColOccupied = true;
      if (col == rowLength - 1) lastColOccupied = true;
    }

    // if there is a piece in the first col and last col, it is "wrapping" through the wall
    return !(firstColOccupied && lastColOccupied);
  }
}
