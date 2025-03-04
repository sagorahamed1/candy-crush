import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candy Crush',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CandyCrushGame(),
    );
  }
}

class CandyCrushGame extends StatefulWidget {
  const CandyCrushGame({super.key});

  @override
  _CandyCrushGameState createState() => _CandyCrushGameState();
}

class _CandyCrushGameState extends State<CandyCrushGame> with SingleTickerProviderStateMixin {
  int gridSize = 8;
  List<List<String>> grid = [];
  List<String> items = ['🍎', '🍌', '🍇', '🍓', '🍒', '🍭', '🎁', '💣']; // Added special candies
  int? selectedRow;
  int? selectedCol;
  List<List<bool>> toRemove = [];
  AnimationController? _animationController;
  bool isAnimating = false;
  int matchesRemaining = 12; // Target matches
  int score = 0;
  int movesLeft = 20; // Move-based level
  int timeLeft = 60; // Time-based level
  Timer? timer;
  // final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initializeGrid();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    startTimer();
  }

  void initializeGrid() {
    grid = List.generate(gridSize, (i) {
      return List.generate(gridSize, (j) {
        return items[Random().nextInt(items.length)];
      });
    });
    toRemove = List.generate(gridSize, (_) => List.filled(gridSize, false));
  }

  void swapTiles(int row1, int col1, int row2, int col2) {
    if (movesLeft <= 0) return; // Prevent swapping if no moves left
    setState(() {
      String temp = grid[row1][col1];
      grid[row1][col1] = grid[row2][col2];
      grid[row2][col2] = temp;
      movesLeft--;
    });
    _playSound('swap.mp3'); // Play swap sound
    checkMatches();
  }

  void checkMatches() {
    bool hasMatches = false;
    toRemove = List.generate(gridSize, (_) => List.filled(gridSize, false));

    // Check for vertical matches
    for (int i = 0; i < gridSize - 2; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j].isNotEmpty && grid[i][j] == grid[i + 1][j] && grid[i][j] == grid[i + 2][j]) {
          toRemove[i][j] = true;
          toRemove[i + 1][j] = true;
          toRemove[i + 2][j] = true;
          hasMatches = true;
        }
      }
    }

    // Check for horizontal matches
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize - 2; j++) {
        if (grid[i][j].isNotEmpty &&
            grid[i][j] == grid[i][j + 1] &&
            grid[i][j] == grid[i][j + 2]) {
          toRemove[i][j] = true;
          toRemove[i][j + 1] = true;
          toRemove[i][j + 2] = true;
          hasMatches = true;
        }
      }
    }

    if (hasMatches) {
      _animationController!.forward(from: 0).then((_) {
        removeMatchedCandies();
      });
    }
  }

  void removeMatchedCandies() {
    setState(() {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          if (toRemove[i][j]) {
            activateSpecialCandy(i, j); // Check for special candies
            grid[i][j] = ''; // Empty string for removed candies
          }
        }
      }
    });
    _playSound('match.mp3'); // Play match sound
    refillGrid();
  }

  void activateSpecialCandy(int row, int col) {
    String candy = grid[row][col];
    if (candy == '🍭') {
      activateStripedCandy(row, col, Random().nextBool());
    } else if (candy == '🎁') {
      activateWrappedCandy(row, col);
    } else if (candy == '💣') {
      activateColorBomb(row, col);
    }
  }

  void activateStripedCandy(int row, int col, bool isHorizontal) {
    setState(() {
      if (isHorizontal) {
        for (int i = 0; i < gridSize; i++) {
          toRemove[row][i] = true;
        }
      } else {
        for (int i = 0; i < gridSize; i++) {
          toRemove[i][col] = true;
        }
      }
    });
  }

  void activateWrappedCandy(int row, int col) {
    setState(() {
      for (int i = row - 1; i <= row + 1; i++) {
        for (int j = col - 1; j <= col + 1; j++) {
          if (i >= 0 && i < gridSize && j >= 0 && j < gridSize) {
            toRemove[i][j] = true;
          }
        }
      }
    });
  }

  void activateColorBomb(int row, int col) {
    String targetCandy = grid[row][col];
    setState(() {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          if (grid[i][j] == targetCandy) {
            toRemove[i][j] = true;
          }
        }
      }
    });
  }

  void refillGrid() {
    setState(() {
      // Shift candies downward
      for (int j = 0; j < gridSize; j++) {
        for (int i = gridSize - 1; i >= 0; i--) {
          if (grid[i][j].isEmpty) {
            for (int k = i - 1; k >= 0; k--) {
              if (grid[k][j].isNotEmpty) {
                grid[i][j] = grid[k][j];
                grid[k][j] = '';
                break;
              }
            }
          }
        }
      }

      // Refill the top rows with new random candies
      for (int j = 0; j < gridSize; j++) {
        for (int i = 0; i < gridSize; i++) {
          if (grid[i][j].isEmpty) {
            grid[i][j] = items[Random().nextInt(items.length)];
          }
        }
      }
    });

    // Update score and matches remaining
    setState(() {
      score += 10; // Increment score for each match
      matchesRemaining--; // Decrement target matches
    });

    // Check for new matches after refilling
    checkMatches();

    // Check if the level is completed
    if (matchesRemaining <= 0) {
      _showLevelCompleteDialog();
    }
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Level Complete!'),
          content: Text('Congratulations! You completed the level with a score of $score.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      initializeGrid();
      score = 0;
      matchesRemaining = 12;
      movesLeft = 20;
      timeLeft = 60;
    });
  }

  void onTileTap(int row, int col) {
    if (selectedRow == null && selectedCol == null) {
      // First tile selected
      setState(() {
        selectedRow = row;
        selectedCol = col;
      });
    } else {
      // Second tile selected, try to swap
      if ((selectedRow == row && (selectedCol == col - 1 || selectedCol == col + 1)) ||
          (selectedCol == col && (selectedRow == row - 1 || selectedRow == row + 1))) {
        swapTiles(selectedRow!, selectedCol!, row, col);
      }
      setState(() {
        selectedRow = null;
        selectedCol = null;
      });
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Time Up!'),
          content: Text('You ran out of time. Try again!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playSound(String soundFile) async {
    // await _audioPlayer.play(AssetSource(soundFile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Candy Crush'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Matches Left: $matchesRemaining',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: $timeLeft',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Moves: $movesLeft',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
              ),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                int row = index ~/ gridSize;
                int col = index % gridSize;
                return GestureDetector(
                  onTap: () => onTileTap(row, col),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      border: toRemove[row][col]
                          ? Border.all(color: Colors.white, width: 3)
                          : selectedRow == row && selectedCol == col
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        grid[row][col],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}