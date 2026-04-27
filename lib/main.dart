import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapCallbacks {
  late Player player;

  @override
  Future<void> onLoad() async {
    player = Player();
    add(player);
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.position = event.canvasPosition;
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
