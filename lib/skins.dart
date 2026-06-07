import 'package:flutter/material.dart';
import 'values.dart';

enum SkinType {
  classic,
  y2k,
  sparkle,
  candy,
}

class TetrisSkin {
  final SkinType type;
  final String name;
  final Map<Tetromino, Color> colors;
  final Map<Tetromino, String>? emojis; // [NEW] Added for emoji skins
  final Color backgroundColor;
  final Color gridLineColor;
  final Color emptyColor;

  TetrisSkin({
    required this.type,
    required this.name,
    required this.colors,
    this.emojis,
    required this.backgroundColor,
    required this.gridLineColor,
    required this.emptyColor,
  });

  static TetrisSkin classic = TetrisSkin(
    type: SkinType.classic,
    name: "Classic",
    colors: tetrominoColors,
    backgroundColor: Colors.black,
    gridLineColor: Colors.grey[800]!,
    emptyColor: Colors.grey[900]!,
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
  );

  static TetrisSkin candy = TetrisSkin(
    type: SkinType.candy,
    name: "Candy Land",
    emojis: {
      Tetromino.I: "🍫", // Chocolate Bar
      Tetromino.L: "🍰", // Strawberry Cake
      Tetromino.J: "🍦", // Soft Ice Cream
      Tetromino.O: "🍩", // Donut
      Tetromino.S: "🍬", // Candy
      Tetromino.Z: "🍭", // Lollipop
      Tetromino.T: "🧁", // Cupcake
    },
    colors: {
      Tetromino.I: const Color(0xFF795548), // Brown
      Tetromino.L: const Color(0xFFFF80AB), // Pink
      Tetromino.J: const Color(0xFFB3E5FC), // Blue
      Tetromino.O: const Color(0xFFFFD54F), // Yellow
      Tetromino.S: const Color(0xFFA5D6A7), // Green
      Tetromino.Z: const Color(0xFFFFAB91), // Orange
      Tetromino.T: const Color(0xFFCE93D8), // Purple
    },
    backgroundColor: const Color(0xFFFFF1F0), // Soft Pinkish White
    gridLineColor: Colors.pink.withAlpha(40),
    emptyColor: const Color(0xFFFFFFFF),
  );

  static TetrisSkin getSkin(SkinType type) {
    switch (type) {
      case SkinType.y2k:
        return y2k;
      case SkinType.sparkle:
        return sparkle;
      case SkinType.candy:
        return candy;
      case SkinType.classic:
        return classic;
    }
  }
}
