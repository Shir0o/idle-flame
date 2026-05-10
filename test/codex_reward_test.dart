import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/meta_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recordDiscovery awards 5 embers by default', () {
    final meta = MetaState();
    addTearDown(meta.dispose);

    expect(meta.embers, 0);
    meta.recordDiscovery('test_id');
    expect(meta.embers, 5);
  });

  test('recordDiscovery supports custom reward amounts', () {
    final meta = MetaState();
    addTearDown(meta.dispose);

    expect(meta.embers, 0);
    meta.recordDiscovery('test_id_50', reward: 50);
    expect(meta.embers, 50);
  });
}
