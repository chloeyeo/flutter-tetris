import 'dart:ui';

int rowLength = 10;
int colLength = 20;

enum Tetromino {
  L,
  J,
  I,
  O,
  S,
  Z,
  T,
}

enum Direction {
  left,
  right,
  down
}

const Map<Tetromino, Color> tetrominoColors = {
  Tetromino.L: Color(0xFFFFA500), // orange
  Tetromino.J: Color.fromARGB(255,0,102,255), // blue
  Tetromino.I: Color.fromARGB(255,242,0,255), // pink
  Tetromino.O: Color(0xFFFFFF00), // yellow
  Tetromino.S: Color(0xFF008000), // green
  Tetromino.Z: Color(0xFFFF0000), // red
  Tetromino.T: Color.fromARGB(255,144,0,255), // purple
};