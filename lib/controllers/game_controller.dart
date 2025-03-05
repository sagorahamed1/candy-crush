import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'dart:async';

class GameController extends GetxController {
  int gridSize = 8;
  var grid = <List<String>>[].obs;
  var toRemove = <List<bool>>[].obs;
  var selectedRow = RxnInt();
  var selectedCol = RxnInt();
  var matchesRemaining = 12.obs;
  var score = 0.obs;
  var movesLeft = 20.obs;
  var timeLeft = 60.obs;
  Timer? timer;
  bool isProcessing = false; // To prevent moves during processing

  List<String> items = ['🍎', '🍌', '🍇', '🍓', '🍒', '🍭', '🎁', '💣'];

  @override
  void onInit() {
    super.onInit();
    initializeGrid();
    startTimer();
  }

  void initializeGrid() {
    grid.value = List.generate(gridSize, (i) {
      return List.generate(gridSize, (j) {
        return items[Random().nextInt(items.length)];
      });
    });
    toRemove.value = List.generate(gridSize, (_) => List.filled(gridSize, false));
    checkMatches(); // Check for initial matches and refill
  }

  void swapTiles(int row1, int col1, int row2, int col2) {
    if (isProcessing || movesLeft.value <= 0) return;

    // Swap candies
    String temp = grid[row1][col1];
    grid[row1][col1] = grid[row2][col2];
    grid[row2][col2] = temp;

    // Check for matches after swap
    if (checkMatches()) {
      movesLeft.value--;
      processMatches();
    } else {
      // Swap back if no matches
      String temp = grid[row1][col1];
      grid[row1][col1] = grid[row2][col2];
      grid[row2][col2] = temp;
    }
  }

  bool checkMatches() {
    toRemove.value = List.generate(gridSize, (_) => List.filled(gridSize, false));
    bool hasMatches = false;

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

    // Check for vertical matches
    for (int j = 0; j < gridSize; j++) {
      for (int i = 0; i < gridSize - 2; i++) {
        if (grid[i][j].isNotEmpty &&
            grid[i][j] == grid[i + 1][j] &&
            grid[i][j] == grid[i + 2][j]) {
          toRemove[i][j] = true;
          toRemove[i + 1][j] = true;
          toRemove[i + 2][j] = true;
          hasMatches = true;
        }
      }
    }

    return hasMatches;
  }

  void processMatches() async {
    isProcessing = true;

    // Highlight matched candies
    await Future.delayed(Duration(milliseconds: 300));

    // Remove matched candies
    removeMatchedCandies();

    // Refill the grid
    await refillGrid();

    // Check for new matches after refill
    if (checkMatches()) {
      processMatches(); // Recursively process cascading matches
    } else {
      isProcessing = false;
    }
  }

  void removeMatchedCandies() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (toRemove[i][j]) {
          activateSpecialCandy(i, j);
          grid[i][j] = '';
          score.value += 10;
        }
      }
    }
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
    if (isHorizontal) {
      for (int i = 0; i < gridSize; i++) {
        toRemove[row][i] = true;
      }
    } else {
      for (int i = 0; i < gridSize; i++) {
        toRemove[i][col] = true;
      }
    }
  }

  void activateWrappedCandy(int row, int col) {
    for (int i = row - 1; i <= row + 1; i++) {
      for (int j = col - 1; j <= col + 1; j++) {
        if (i >= 0 && i < gridSize && j >= 0 && j < gridSize) {
          toRemove[i][j] = true;
        }
      }
    }
  }

  void activateColorBomb(int row, int col) {
    String targetCandy = grid[row][col];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == targetCandy) {
          toRemove[i][j] = true;
        }
      }
    }
  }



  Future<void> refillGrid() async {
    // Refill only the specific rows or columns where matches occurred
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (toRemove[i][j]) {
          // Refill the specific column
          refillColumn(j);
        }
      }
    }

    await Future.delayed(Duration(seconds: 1)); // Simulate falling animation
  }

  Future<void> refillColumn(int col) async {
    int emptySpaces = 0;

    // Traverse from bottom to top in the specific column
    for (int i = gridSize - 1; i >= 0; i--) {
      if (grid[i][col].isEmpty) {
        emptySpaces++; // Count empty spaces
      } else if (emptySpaces > 0) {
        // Shift the candy down to fill the empty space
        grid[i + emptySpaces][col] = grid[i][col];
        grid[i][col] = ''; // Clear the original position

        // Add a delay to simulate the falling animation
        await Future.delayed(Duration(milliseconds: 600)); // Adjust delay as needed
      }
    }

    // Fill the top empty spaces with new candies
    for (int i = 0; i < emptySpaces; i++) {
      grid[i][col] = items[Random().nextInt(items.length)]; // Generate new candy

      // Add a delay to simulate the falling animation for new candies
      await Future.delayed(Duration(milliseconds: 600)); // Adjust delay as needed
    }
  }


  void onTileTap(int row, int col) {
    if (isProcessing) return;

    if (selectedRow.value == null && selectedCol.value == null) {
      // First tile selected
      selectedRow.value = row;
      selectedCol.value = col;
    } else {
      // Second tile selected, try to swap
      if ((selectedRow.value == row && (selectedCol.value == col - 1 || selectedCol.value == col + 1)) ||
          (selectedCol.value == col && (selectedRow.value == row - 1 || selectedRow.value == row + 1))) {
        swapTiles(selectedRow.value!, selectedCol.value!, row, col);
      }
      // Clear selection
      selectedRow.value = null;
      selectedCol.value = null;
    }
  }

  void resetGame() {
    initializeGrid();
    score.value = 0;
    matchesRemaining.value = 12;
    movesLeft.value = 20;
    timeLeft.value = 60;
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        timer.cancel();
        Get.dialog(
          AlertDialog(
            title: Text('Time Up!'),
            content: Text('You ran out of time. Try again!'),
            actions: [
              TextButton(
                onPressed: () {
                  resetGame();
                  Get.back();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
    });
  }
}