import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/game_controller.dart';

class GameScreen extends StatelessWidget {
  final GameController _controller = Get.put(GameController());

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
                Obx(() => Text('Score: ${_controller.score.value}')),
                Obx(() => Text('Matches Left: ${_controller.matchesRemaining.value}')),
                Obx(() => Text('Time: ${_controller.timeLeft.value}')),
                Obx(() => Text('Moves: ${_controller.movesLeft.value}')),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              print(_controller.score.value);
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _controller.gridSize,
                ),
                itemCount: _controller.gridSize * _controller.gridSize,
                itemBuilder: (context, index) {
                  int row = index ~/ _controller.gridSize;
                  int col = index % _controller.gridSize;
                  return GestureDetector(
                    onTap: () => _controller.onTileTap(row, col),
                    child: Container(
                      margin: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        border: _controller.toRemove[row][col]
                            ? Border.all(color: Colors.white, width: 3)
                            : _controller.selectedRow.value == row && _controller.selectedCol.value == col
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _controller.grid[row][col],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}