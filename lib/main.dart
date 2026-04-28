import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

void main() {
  // Ensure Flutter is initialized before running the game
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF0D0D1A);

  @override
  Future<void> onLoad() async {
    // Set the camera to view the world from the top-left corner
    // This makes world coordinates match screen coordinates (0,0 is top-left)
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    
    // Add a simple ground line to verify rendering on mobile
    world.add(RectangleComponent(
      size: Vector2(size.x, 20),
      position: Vector2(0, size.y - 50),
      paint: Paint()..color = const Color(0xFF222233),
    ));

    // Add fortress to the world
    world.add(Fortress());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update ground size when screen resizes
    children.query<RectangleComponent>().forEach((ground) {
      ground.size = Vector2(size.x, 20);
      ground.position = Vector2(0, size.y - 20);
    });
  }
}

class Fortress extends SpriteComponent with HasGameRef<MyGame> {
  Fortress() : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      sprite = await gameRef.loadSprite('fortress/rotations/north.png');
    } catch (e) {
      print('Error loading fortress sprite: $e');
    }
    
    // Size it nicely for a mobile screen
    size = Vector2.all(200);
    _updatePosition();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updatePosition();
  }

  void _updatePosition() {
    // Position at the bottom center of the screen
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
  }
}
