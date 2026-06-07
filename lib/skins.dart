import 'package:flutter/material.dart';
import 'values.dart';

enum SkinType {
  classic,
  y2k,
  sparkle,
  candy,
  chalkboard,
}

class TetrisSkin {
  final SkinType type;
  final String name;
  final Map<Tetromino, Color> colors;
  final Map<Tetromino, String>? emojis;
  final Color backgroundColor;
  final Color gridLineColor;
  final Color emptyColor;
  final Color textColor;
  final String? landSound; // [NEW] Asset path for landing sound
  final String? clearSound; // [NEW] Asset path for line clear sound

  TetrisSkin({
    required this.type,
    required this.name,
    required this.colors,
    this.emojis,
    required this.backgroundColor,
    required this.gridLineColor,
    required this.emptyColor,
    required this.textColor,
    this.landSound,
    this.clearSound,
  });

  static TetrisSkin classic = TetrisSkin(
    type: SkinType.classic,
    name: "Classic",
    colors: tetrominoColors,
    backgroundColor: Colors.black,
    gridLineColor: Colors.grey[800]!,
    emptyColor: Colors.grey[900]!,
    textColor: Colors.white,
  );

  static TetrisSkin y2k = TetrisSkin(
    type: SkinType.y2k,
    name: "Y2K Neon",
    colors: {
      Tetromino.L: const Color(0xFFFF00FF), // Neon Pink
      Tetromino.J: const Color(0xFF00FFFF), // Cyan
      Tetromino.I: const Color(0xFFFFFF00), // Yellow
      Tetromino.O: const Color(0xFF00FF00), // Lime
      Tetromino.S: const Color(0xFFFF4500), // OrangeRed
      Tetromino.Z: const Color(0xFFADFF2F), // GreenYellow
      Tetromino.T: const Color(0xFF7B68EE), // MediumSlateBlue
    },
    backgroundColor: const Color(0xFF000033), // Dark Midnight Blue
    gridLineColor: const Color(0xFF333399).withAlpha(127),
    emptyColor: const Color(0xFF000022),
    textColor: Colors.white,
  );

  static TetrisSkin sparkle = TetrisSkin(
    type: SkinType.sparkle,
    name: "Shiny Sparkles",
    colors: {
      Tetromino.L: const Color(0xFFF8BBD0), // Pastel Pink
      Tetromino.J: const Color(0xFFB2EBF2), // Pastel Blue
      Tetromino.I: const Color(0xFFE1BEE7), // Pastel Purple
      Tetromino.O: const Color(0xFFFFF9C4), // Pastel Yellow
      Tetromino.S: const Color(0xFFC8E6C9), // Pastel Green
      Tetromino.Z: const Color(0xFFFFCCBC), // Pastel Orange
      Tetromino.T: const Color(0xFFD1C4E9), // Deep Purple
    },
    backgroundColor: const Color(0xFF1A1A1A),
    gridLineColor: Colors.white.withAlpha(30),
    emptyColor: const Color(0xFF222222),
    textColor: Colors.white,
  );

  static TetrisSkin candy = TetrisSkin(
    type: SkinType.candy,
    name: "Candy Land",
    emojis: {
      Tetromino.I: "🍫",
      Tetromino.L: "🍰",
      Tetromino.J: "🍦",
      Tetromino.O: "🍩",
      Tetromino.S: "🍬",
      Tetromino.Z: "🍭",
      Tetromino.T: "🧁",
    },
    colors: {
      Tetromino.I: const Color(0xFF795548),
      Tetromino.L: const Color(0xFFFF80AB),
      Tetromino.J: const Color(0xFFB3E5FC),
      Tetromino.O: const Color(0xFFFFD54F),
      Tetromino.S: const Color(0xFFA5D6A7),
      Tetromino.Z: const Color(0xFFFFAB91),
      Tetromino.T: const Color(0xFFCE93D8),
    },
    backgroundColor: const Color(0xFFFFF1F0),
    gridLineColor: Colors.pink.withAlpha(40),
    emptyColor: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF5D4037), // Dark Chocolate Brown for contrast
  );

  static TetrisSkin chalkboard = TetrisSkin(
    type: SkinType.chalkboard,
    name: "Chalk Board",
    colors: {
      Tetromino.I: const Color(0xFFE0F7FA), // Chalk Blue
      Tetromino.L: const Color(0xFFFFF9C4), // Chalk Yellow
      Tetromino.J: const Color(0xFFE1BEE7), // Chalk Purple
      Tetromino.O: const Color(0xFFFFFFFF), // Chalk White
      Tetromino.S: const Color(0xFFC8E6C9), // Chalk Green
      Tetromino.Z: const Color(0xFFFFCCBC), // Chalk Red
      Tetromino.T: const Color(0xFFFCE4EC), // Chalk Pink
    },
    backgroundColor: const Color(0xFF004D40), // Deep Chalkboard Green
    gridLineColor: Colors.white.withAlpha(20),
    emptyColor: const Color(0xFF003D33),
    textColor: Colors.white.withAlpha(200),
    landSound: "sounds/chalk_land.wav",
    clearSound: "sounds/eraser_swipe.wav",
  );

  static TetrisSkin getSkin(SkinType type) {
    switch (type) {
      case SkinType.y2k:
        return y2k;
      case SkinType.sparkle:
        return sparkle;
      case SkinType.candy:
        return candy;
      case SkinType.chalkboard:
        return chalkboard;
      case SkinType.classic:
        return classic;
    }
  }
}
