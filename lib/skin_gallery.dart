import 'package:flutter/material.dart';
import 'skins.dart';

class SkinGallery extends StatefulWidget {
  final List<SkinType> unlockedSkins;
  final TetrisSkin currentSkin;
  final Function(TetrisSkin) onSkinSelected;
  final Function(SkinType) onUnlockSkin;

  const SkinGallery({
    super.key,
    required this.unlockedSkins,
    required this.currentSkin,
    required this.onSkinSelected,
    required this.onUnlockSkin,
  });

  @override
  State<SkinGallery> createState() => _SkinGalleryState();
}

class _SkinGalleryState extends State<SkinGallery> {
  late List<SkinType> _tempUnlockedSkins;
  late TetrisSkin _tempCurrentSkin;

  @override
  void initState() {
    super.initState();
    _tempUnlockedSkins = List.from(widget.unlockedSkins);
    _tempCurrentSkin = widget.currentSkin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Skins Gallery", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white), // Make back button white
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: SkinType.values.length,
        itemBuilder: (context, index) {
          final skinType = SkinType.values[index];
          final skin = TetrisSkin.getSkin(skinType);
          final isUnlocked = _tempUnlockedSkins.contains(skinType);
          final isSelected = _tempCurrentSkin.type == skinType;

          return GestureDetector(
            onTap: () {
              if (isUnlocked) {
                setState(() {
                  _tempCurrentSkin = skin;
                });
                widget.onSkinSelected(skin);
              } else {
                _showUnlockDialog(context, skinType);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSkinPreview(skin),
                  const SizedBox(height: 10),
                  Text(
                    skin.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  if (!isUnlocked)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey, size: 16),
                        SizedBox(width: 5),
                        Text("Watch Ad", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                  else if (isSelected)
                    const Text("EQUIPPED", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
                  else
                    const Text("UNLOCKED", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, SkinType skinType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Unlock Skin", style: TextStyle(color: Colors.white)),
        content: Text(
          "Watch a rewarded ad to unlock the ${skinType.name} skin permanently?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUnlockSkin(skinType);
              // Optimistically update UI
              setState(() {
                if (!_tempUnlockedSkins.contains(skinType)) {
                  _tempUnlockedSkins.add(skinType);
                }
              });
            },
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinPreview(TetrisSkin skin) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: skin.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        children: [
          _buildPreviewPixel(skin.colors.values.elementAt(0), skin.type),
          _buildPreviewPixel(skin.colors.values.elementAt(1), skin.type),
          _buildPreviewPixel(skin.colors.values.elementAt(2), skin.type),
          _buildPreviewPixel(skin.colors.values.elementAt(3), skin.type),
        ],
      ),
    );
  }

  Widget _buildPreviewPixel(Color color, SkinType type) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(type == SkinType.y2k ? 1 : 2),
      ),
    );
  }
}
