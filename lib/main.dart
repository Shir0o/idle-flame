import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapDetector {
  late Player player;

  @override
  Future<void> onLoad() async {
    player = Player();
    add(player);
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.position = info.eventPosition.global;
  }
}

class Player extends PositionComponent with HasGameRef<MyGame> {
  static final _paint = Paint()..color = Colors.orange;

  Player() {
    size = Vector2.all(50);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }
}
