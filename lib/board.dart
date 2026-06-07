import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Touch Accumulators for smooth movement
  double _horizontalAccumulator = 0;
  double _verticalAccumulator = 0;
  final double _moveThreshold = 0.1; // Distance in pixels to move 1 block
  DateTime _lastHorizontalMoveTime = DateTime.now();
  final int _horizontalMoveDelay = 140; // delay (the "notch" feel)

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Lazy Load Ads: Wait 5 seconds before starting the ad handshake
    // This gives the game board priority during startup
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _initAds();
      }
    });
    
    startGame();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final skinIndex = prefs.getInt('current_skin') ?? 0;
      currentSkin = TetrisSkin.getSkin(SkinType.values[skinIndex]);
      
      final unlockedList = prefs.getStringList('unlocked_skins') ?? ['classic'];
      unlockedSkins = unlockedList.map((e) => SkinType.values.firstWhere((s) => s.name == e)).toList();
    });
  }

  void _initAds() {
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
        Duration frameRate = const Duration(milliseconds: 2000); // CONSISTENT SLOW SPEED
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
    Duration frameRate = const Duration(milliseconds: 400); // SLOW START (was 100ms)
    
    // Start the game loop immediately
    if (mounted) {
      gameLoop(frameRate);
    }
  }

  void gameLoop(Duration frameRate) {
    // CANCEL ANY EXISTING TIMER TO PREVENT SPEED-UP BUG
    timer?.cancel();

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
        backgroundColor: currentSkin.backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: currentSkin.gridLineColor, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Game Over",
          style: TextStyle(color: currentSkin.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Your score is: $currentScore",
          style: TextStyle(color: currentSkin.textColor.withAlpha(180)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: Text(
              "Play Again",
              style: TextStyle(color: currentSkin.textColor, fontWeight: FontWeight.bold),
            ),
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
        child: Stack(
          children: [
            Column(
              children: [
                // Top Row for Hold and Next
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hold Piece
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: holdPiece,
                        child: Column(
                          children: [
                            Text("HOLD", style: TextStyle(color: currentSkin.textColor, fontSize: 12)),
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
                        behavior: HitTestBehavior.opaque,
                        onTap: _openSkinGallery,
                        child: Column(
                          children: [
                            Text("SKINS", style: TextStyle(color: currentSkin.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
                          Text("SCORE", style: TextStyle(color: currentSkin.textColor, fontSize: 12)),
                          Text(
                            '$currentScore',
                            style: TextStyle(color: currentSkin.textColor, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      // Next Piece
                      Column(
                        children: [
                          Text("NEXT", style: TextStyle(color: currentSkin.textColor, fontSize: 12)),
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
                    behavior: HitTestBehavior.opaque, // Ensure even empty space catches touch
                    dragStartBehavior: DragStartBehavior.down, // [NEW] Removes initial "waiting" period for touch
                    onTap: rotatePiece,
                onPanStart: (details) {
                  // Reset accumulators when a new touch starts
                  _horizontalAccumulator = 0;
                  _verticalAccumulator = 0;
                },
                onPanUpdate: (details) {
                  // Add the change in position to our accumulators
                  double dx = details.delta.dx;
                  double dy = details.delta.dy;

                  // AXIS LOCK: If horizontal movement is dominant, ignore vertical to prevent accidental drops
                  if (dx.abs() > dy.abs()) {
                    _horizontalAccumulator += dx;
                  } else if (dy > 0) {
                    // Only accumulate vertical if moving DOWN and it's the dominant movement
                    _verticalAccumulator += dy;
                  }

                  final now = DateTime.now();
                  final timeSinceLastMove = now.difference(_lastHorizontalMoveTime).inMilliseconds;

                  // NOTCHED MOVEMENT: Checks distance AND adds a tiny time delay
                  // This creates the "gear-like" feel where each step is distinct
                  if (_horizontalAccumulator.abs() >= _moveThreshold && timeSinceLastMove > _horizontalMoveDelay) {
                    setState(() {
                      if (_horizontalAccumulator > 0) {
                        moveRight();
                      } else {
                        moveLeft();
                      }
                    });
                    
                    // Add Haptic Feedback for tactile "snap" feel
                    HapticFeedback.selectionClick();

                    // [BRAKE LOGIC] Reset to 0 after movement to prevent "gliding"
                    _horizontalAccumulator = 0;
                    _lastHorizontalMoveTime = now;
                  }

                  // Process vertical movement (Soft Drop) with a higher threshold to prevent accidents
                  if (_verticalAccumulator >= 60.0) {
                    if (!checkCollision(Direction.down)) {
                      setState(() {
                        currentPiece.movePiece(Direction.down);
                      });
                    }
                    _verticalAccumulator = 0;
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
                        // PRE-CALCULATE GHOST POSITION ONCE PER BUILD
                        // This prevents 200 calculations per frame, making touch instant
                        final ghostPosition = getGhostPosition();

                        // calculate best fit size for the grid
                        double availableWidth = constraints.maxWidth;
                        double availableHeight = constraints.maxHeight;
                        
                        // Force a fixed 1:2 aspect ratio for the board (standard Tetris)
                        double pixelSize = min(
                          availableWidth / rowLength, 
                          availableHeight / colLength
                        );

                        // Ensure the container itself has a fixed size to prevent shifting
                        double boardWidth = pixelSize * rowLength;
                        double boardHeight = pixelSize * colLength;

                        return Center(
                          child: SizedBox(
                            width: boardWidth,
                            height: boardHeight,
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
                                      emoji: currentSkin.emojis?[currentPiece.type],
                                    );
                                  }
                                  // if it's the ghost piece, draw it
                                  else if (ghostPosition.contains(index)) {
                                    return Pixel(
                                      color: (currentSkin.colors[currentPiece.type] ?? currentPiece.color).withAlpha(76), // ~0.3 opacity
                                      skinType: currentSkin.type,
                                      emoji: currentSkin.emojis?[currentPiece.type],
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
                                      emoji: currentSkin.emojis?[tetrominoType],
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
                  padding: const EdgeInsets.only(bottom: 55.0), // Extra space for the floating ad
                  child: Text(
                    "Tap to rotate • Swipe to move • Tap HOLD box to swap",
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ),
              ],
            ),

            // Floating Ad Container at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 50,
                child: _isBannerLoaded
                    ? AdWidget(ad: _bannerAd!)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
