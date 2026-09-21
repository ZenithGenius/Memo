import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Les tests supposent une interface en français, comme l'application quand le
/// profil est en français : sans cela, la langue de l'environnement de test
/// (anglais) serait utilisée par les hôtes de test sans langue explicite.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [Locale('fr')];
  });
  await testMain();
}
