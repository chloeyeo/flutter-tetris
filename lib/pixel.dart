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
        borderRadius: BorderRadius.circular(skinType == SkinType.y2k ? 2 : 4),
        border: Border.all(
          color: skinType == SkinType.y2k 
              ? Colors.white.withAlpha(100) 
              : Colors.black.withAlpha(30),
          width: skinType == SkinType.y2k ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.all(1),
      child: emoji != null
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
