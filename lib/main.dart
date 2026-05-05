import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/idle_game.dart';
import 'game/state/game_state.dart';
import 'game/state/meta_state.dart';
import 'ui/hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final meta = MetaState();
  await meta.load();
  final state = GameState(meta: meta);
  await state.load();
  runApp(IdleFlameApp(state: state, meta: meta));
}

class IdleFlameApp extends StatelessWidget {
  const IdleFlameApp({super.key, required this.state, required this.meta});

  final GameState state;
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: state),
        ChangeNotifierProvider<MetaState>.value(value: meta),
      ],
      child: MaterialApp(
        title: 'Zenith Zero',
        debugShowCheckedModeBanner: false,
        home: _AppLifecycle(
          state: state,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: GameWidget(game: IdleGame(state: state)),
                ),
                const Hud(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppLifecycle extends StatefulWidget {
  const _AppLifecycle({required this.state, required this.child});

  final GameState state;
  final Widget child;

  @override
  State<_AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends State<_AppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      widget.state.save();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
