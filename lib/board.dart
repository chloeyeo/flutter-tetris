import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris/piece.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';

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
  int currentScore = 0;
  // game over status
  bool gameOver = false;
  Timer? timer;

  // random generator
  final Random rand = Random();

  // piece bag for 7-bag system
  List<Tetromino> pieceBag = [];

  @override
  void initState() {
    super.initState();

    startGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGame() {
    currentPiece.initializePiece();
    Duration frameRate = const Duration(milliseconds: 200);
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
    createNewPiece();
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
    // create a random object to generate random tetromino types
    Random rand = Random();

    // create a new piece with random type
    Tetromino randomType = Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    /*
    Since our game over condition is if there is a piece at the top level,
    we want to check if the game is over when you create a new piece
    instead of checking every frame, because new pieces are allowed to
    go through the top level but if there is already a piece in the top level
    when the new piece is created, then game is over.
     */
    if (isGameOver()) {
      gameOver = true;
    }
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

  // rotate piece
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
        gameBoard[0] = List.generate(row, (index)=>null);

        // increase score
        currentScore++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                                color: currentPiece.color,
                              );
                            }
                            // if there's a landed piece at this coordinate, draw it
                            else if (gameBoard[row][col] != null) {
                              final Tetromino? tetrominoType =
                                  gameBoard[row][col];
                              return Pixel(
                                color: tetrominoColors[tetrominoType],
                              );
                            }
                            // otherwise, it is just an empty space.
                            else {
                              return Pixel(
                                color: Colors.grey[900],
                              );
                            }
                          }),
                    ),
                  );
                },
              ),
            ),

            // SCORE
            Text(
              'Score: $currentScore',
              style: TextStyle(color: Colors.white),
            ),

            // GAME CONTROLS
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0, top: 10.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // left
                    IconButton(
                        onPressed: moveLeft,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_ios)),

                    // rotate
                    IconButton(
                        onPressed: rotatePiece,
                        color: Colors.white,
                        icon: const Icon(Icons.rotate_right)),

                    // right
                    IconButton(
                        onPressed: moveRight,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_forward_ios)),
                  ]),
            ) // Row
          ],
        ),
      ), // Column
    ); // Scaffold
  }
}