import 'dart:math';

import 'package:flutter/material.dart';
import 'skins.dart';

class Pixel extends StatelessWidget {
  final Color color;
  final SkinType skinType;
  final String? emoji; // [NEW] Optional emoji for legendary skins

  const Pixel({
    super.key,
    required this.color,
    this.skinType = SkinType.classic,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          skinType == SkinType.y2k ? 2 : (skinType == SkinType.chalkboard ? 1 : 4),
        ),
        border: skinType == SkinType.chalkboard
            ? Border.all(
                color: Colors.white.withAlpha(180),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignCenter,
              )
            : Border.all(
                color: skinType == SkinType.y2k 
                    ? Colors.white.withAlpha(100) 
                    : Colors.black.withAlpha(30),
                width: skinType == SkinType.y2k ? 2 : 1,
              ),
      ),
      margin: const EdgeInsets.all(1),
      child: skinType == SkinType.chalkboard
          ? CustomPaint(
              painter: ChalkTexturePainter(),
            )
          : emoji != null
              ? Center(
                  child: Text(
                    emoji!,
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              : skinType == SkinType.sparkle
                  ? Stack(
                      children: [
                        Positioned(
                          top: 2,
                          left: 2,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 8,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Icon(
                            Icons.star,
                            size: 6,
                            color: Colors.white.withAlpha(100),
                          ),
                        ),
                      ],
                    )
                  : null,
    );
  }
}

class ChalkTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 1.0;

    // Draw some random dots to simulate chalk dust
    final random = Random();
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
