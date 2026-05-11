import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/meta_state.dart';
import 'package:zenith_zero/ui/hud.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameState state;
  late MetaState meta;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    meta = MetaState();
    await meta.load();
    state = GameState(meta: meta);
    await state.load();
  });

  Widget buildHud() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: state),
        ChangeNotifierProvider<MetaState>.value(value: meta),
      ],
      child: const MaterialApp(home: Scaffold(body: Hud())),
    );
  }

  group('HUD Widget Tests', () {
    testWidgets('Gold display updates when state changes', (tester) async {
      await tester.pumpWidget(buildHud());

      expect(find.text('0'), findsOneWidget); // Initial gold

      state.gold = 1234;
      state.notifyListeners(); // Force update if not triggered automatically
      await tester.pump();

      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('Nexus HP bar shows current health', (tester) async {
      await tester.pumpWidget(buildHud());

      // Default health is 100/100
      expect(find.text('100/100'), findsOneWidget);

      state.nexusHp = 45.6;
      state.notifyListeners();
      await tester.pump();

      expect(find.text('46/100'), findsOneWidget); // ceil() is used for display
    });

    testWidgets('Floor display updates', (tester) async {
      await tester.pumpWidget(buildHud());

      expect(find.text('Floor 1'), findsOneWidget);

      state.floor = 5;
      state.notifyListeners();
      await tester.pump();

      expect(find.text('Floor 5'), findsOneWidget);
      expect(find.text('BOSS'), findsOneWidget);
    });
  });
}
