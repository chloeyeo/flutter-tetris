import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris/piece.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';
import 'package:tetris/skins.dart';
import 'package:tetris/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tetris/skin_gallery.dart';
import 'package:tetris/piece_preview.dart';

/*
Game board is a 2x2 grid with null representing an empty space.
A non empty space will have the color to represent the landed pieces.
*/

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {

  // create game board
  List<List<Tetromino?>> gameBoard = List.generate(
    colLength,
        (i) => List.generate(
      rowLength,
          (j) => null,
    ),
  );

  Piece currentPiece = Piece(type: Tetromino.L)..initializePiece();
  Piece? nextPiece;
  Piece? heldPiece;
  bool canHold = true;
  int currentScore = 0;
  // game over status
  bool gameOver = false;
  Timer? timer;

  // Skin System
  TetrisSkin currentSkin = TetrisSkin.classic;
  List<SkinType> unlockedSkins = [SkinType.classic];

  // Ads
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final AdService _adService = AdService();

  // random generator
  final Random rand = Random();

  // piece bag for 7-bag system
  List<Tetromino> pieceBag = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initAds();
    startGame();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final skinIndex = prefs.getInt('current_skin') ?? 0;
      currentSkin = TetrisSkin.getSkin(SkinType.values[skinIndex]);
      
      final unlockedList = prefs.getStringList('unlocked_skins') ?? ['classic'];
      unlockedSkins = unlockedList.map((e) => SkinType.values.firstWhere((s) => s.name == e)).toList();
    });
  }

  void _initAds() async {
    await _adService.init();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _openSkinGallery() {
    // PAUSE GAME
    timer?.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkinGallery(
          unlockedSkins: unlockedSkins,
          currentSkin: currentSkin,
          onSkinSelected: (skin) async {
            setState(() {
              currentSkin = skin;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_skin', skin.type.index);
          },
          onUnlockSkin: (skinType) {
            _adService.loadRewardedAd(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() {
                  unlockedSkins.add(skinType);
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('unlocked_skins', unlockedSkins.map((e) => e.name).toList());
                
                messenger.showSnackBar(
                  SnackBar(content: Text("${skinType.name} skin unlocked!")),
                );
              },
              onAdFailedToLoad: () {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to load ad. Try again later.")),
                );
              },
            );
          },
        ),
      ),
    ).then((_) {
      // RESUME GAME WHEN RETURNING FROM GALLERY
      if (!gameOver) {
        Duration frameRate = const Duration(milliseconds: 600);
        gameLoop(frameRate);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void startGame() {
    currentPiece.initializePiece();
    generateNextPiece();
    Duration frameRate = const Duration(milliseconds: 600); // SLOWER SPEED
    gameLoop(frameRate);
  }

  void gameLoop(Duration frameRate) {
    timer = Timer.periodic(
      frameRate,
      (timer) {
        if (!mounted) return;
        setState(() {
          // clear lines
          clearLines();

          // check landing
          checkLanding();

          // check if game is over
          if (gameOver) {
            timer.cancel();
            showGameOverDialog();
          }

          // move current piece down
          if (!checkCollision(Direction.down)) {
            currentPiece.movePiece(Direction.down);
          }
        });
      },
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Your score is: $currentScore"),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: const Text("Play Again"),
          )
        ],
      ),
    );
  }

  void resetGame() {
    // clear the game board
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );
    gameOver = false;
    currentScore = 0;
    heldPiece = null;
    canHold = true;
    pieceBag = [];
    currentPiece = Piece(type: Tetromino.L)..initializePiece();
    nextPiece = null;
    startGame();
  }

  // collision detection (check for collision in a future position)
  // return True if there is a collision, else False
  bool checkCollision(Direction direction) {
    // loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      // calculate row and column of current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;
      if (col < 0) col += rowLength;

      // adjust the row and col based on direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      // check if piece is out of bounds
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      // check if the pixel is already occupied
      if (row >= 0 && gameBoard[row][col] != null) {
        return true;
      }
    }
    // if no collisions are found, return false
    return false;
  }

  void checkLanding() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      // mark position as occupied on the game board
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (col < 0) col += rowLength;

        if (row >= 0 && row < colLength && col >= 0 && col < rowLength) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      // once landed, check if it's game over
      if (isGameOver()) {
        gameOver = true;
      }

      // reset hold capability for next piece
      canHold = true;

      // create the next piece
      createNewPiece();
    }
  }

  bool isGameOver() {
    // check if any pixels in the top row are occupied
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    // if top row is empty, game is not over
    return false;
  }

  void createNewPiece() {
    // Get piece from bag/nextPiece
    if (nextPiece == null) {
      generateNextPiece();
    }
    
    currentPiece = nextPiece!;
    currentPiece.initializePiece();
    generateNextPiece();

    if (isGameOver()) {
      gameOver = true;
    }
  }

  void generateNextPiece() {
    if (pieceBag.isEmpty) {
      pieceBag = Tetromino.values.toList();
      pieceBag.shuffle();
    }
    nextPiece = Piece(type: pieceBag.removeAt(0));
  }

  void holdPiece() {
    if (!canHold) return;

    setState(() {
      if (heldPiece == null) {
        heldPiece = Piece(type: currentPiece.type);
        createNewPiece();
      } else {
        Tetromino temp = currentPiece.type;
        currentPiece = Piece(type: heldPiece!.type);
        currentPiece.initializePiece();
        heldPiece = Piece(type: temp);
      }
      canHold = false;
    });
  }

  List<int> getGhostPosition() {
    List<int> ghostPosition = List.from(currentPiece.position);
    bool collision = false;

    while (!collision) {
      // simulate moving down
      List<int> nextPosition = ghostPosition.map((p) => p + rowLength).toList();
      
      // check collision for nextPosition
      for (int pos in nextPosition) {
        int r = (pos / rowLength).floor();
        int c = pos % rowLength;
        if (c < 0) c += rowLength;

        if (r >= colLength || (r >= 0 && gameBoard[r][c] != null)) {
          collision = true;
          break;
        }
      }
      
      if (!collision) {
        ghostPosition = nextPosition;
      }
    }
    return ghostPosition;
  }

  // move left
  void moveLeft() {
    // if there isn't a collision, then we can move
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }

  }

  // move right
  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }

  }

  // hard drop
  void hardDrop() {
    while (!checkCollision(Direction.down)) {
      setState(() {
        currentPiece.movePiece(Direction.down);
      });
    }
    // force land
    checkLanding();
  }

  IconData _getTetrominoIcon(Tetromino type) {
    switch (type) {
      case Tetromino.L:
        return Icons.turn_right;
      case Tetromino.J:
        return Icons.turn_left;
      case Tetromino.I:
        return Icons.maximize;
      case Tetromino.O:
        return Icons.square;
      case Tetromino.S:
        return Icons.waves;
      case Tetromino.Z:
        return Icons.straighten;
      case Tetromino.T:
        return Icons.publish;
    }
  }

  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece(gameBoard);
    });
  }

  void clearLines() {
    // loop through each row of the game board from bottom to top
    for (int row=colLength-1;row>=0;row--) {
      bool rowIsFull = true;

      for (int col=0; col < rowLength; col++) {
        // if there's an empty column, set rowIsFull to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // if row is full, clear row and shift rows down
      if (rowIsFull) {
        // move all rows above the cleared row down by one position
        for (int r=row; r>0; r--) {
          // copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r-1]);
        }

        // set the top row to empty
        gameBoard[0] = List.generate(rowLength, (index) => null);

        // increase score
        currentScore++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentSkin.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Row for Hold and Next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hold Piece
                  GestureDetector(
                    onTap: holdPiece,
                    child: Column(
                      children: [
                        const Text("HOLD", style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(height: 5),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: currentSkin.gridLineColor),
                          ),
                          child: heldPiece != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: PiecePreview(
                                      type: heldPiece!.type,
                                      skin: currentSkin,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // Skins Gallery
                  GestureDetector(
                    onTap: _openSkinGallery,
                    child: Column(
                      children: [
                        const Text("SKINS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(color: Colors.blue),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.palette, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Score
                  Column(
                    children: [
                      const Text("SCORE", style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(
                        '$currentScore',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // Next Piece
                  Column(
                    children: [
                      const Text("NEXT", style: TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 5),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: currentSkin.gridLineColor),
                        ),
                        child: nextPiece != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: PiecePreview(
                                    type: nextPiece!.type,
                                    skin: currentSkin,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: GestureDetector(
                onTap: rotatePiece,
                onPanUpdate: (details) {
                  // Sensitivity threshold - ADJUSTED FOR ACCURATE MOBILE FEEL
                  if (details.delta.dx > 6) {
                    moveRight();
                  } else if (details.delta.dx < -6) {
                    moveLeft();
                  }
                  
                  if (details.delta.dy > 8) {
                    // move down faster
                    if (!checkCollision(Direction.down)) {
                      setState(() {
                        currentPiece.movePiece(Direction.down);
                      });
                    }
                  }
                },
                onVerticalDragEnd: (details) {
                  // detect sharp downward flick for hard drop
                  if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                    hardDrop();
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // calculate best fit size for the grid
                    double availableWidth = constraints.maxWidth;
                    double availableHeight = constraints.maxHeight;
                    double pixelSize =
                        min(availableWidth / rowLength, availableHeight / colLength);

                    return Center(
                      child: SizedBox(
                        width: pixelSize * rowLength,
                        height: pixelSize * colLength,
                        child: GridView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: rowLength * colLength,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: rowLength),
                            itemBuilder: (context, index) {
                              // calculate the row and col of this specific pixel
                              int row = (index / rowLength).floor();
                              int col = index % rowLength;

                              // if it's the current falling piece, draw it
                              if (currentPiece.position.contains(index)) {
                                return Pixel(
                                  color: currentSkin.colors[currentPiece.type] ?? currentPiece.color,
                                  skinType: currentSkin.type,
                                );
                              }
                              // if it's the ghost piece, draw it
                              else if (getGhostPosition().contains(index)) {
                                return Pixel(
                                  color: (currentSkin.colors[currentPiece.type] ?? currentPiece.color).withAlpha(76), // ~0.3 opacity
                                  skinType: currentSkin.type,
                                );
                              }
                              // if there's a landed piece at this coordinate, draw it
                              else if (gameBoard[row][col] != null) {
                                final Tetromino? tetrominoType =
                                    gameBoard[row][col];
                                return Pixel(
                                  color: currentSkin.colors[tetrominoType] ??
                                      Colors.white,
                                  skinType: currentSkin.type,
                                );
                              }
                              // otherwise, it is just an empty space.
                              else {
                                return Pixel(
                                  color: currentSkin.emptyColor,
                                  skinType: currentSkin.type,
                                );
                              }
                            }),
                      ),
                    );
                  },
                ),
              ),
            ),

            // FOOTER (Optional additional info)
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(
                "Tap to rotate • Swipe to move • Tap HOLD box to swap",
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),

            if (_isBannerLoaded)
              SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ), // Column
    ); // Scaffold
  }
}