import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/router/app_router.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('appui long : favori ajouté, confirmé, puis retiré depuis « Mes '
      'favoris » avec possibilité d\'annuler', (tester) async {
    final app = await AppHarness.start(tester);
    Future<Set<int>> ids() => app.container.read(favoriteIdsProvider.future);

    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Fini').first);
    await settleDatabase(tester);
    expect(find.text('Ajouté aux favoris : Fini'), findsOneWidget);
    expect(await ids(), hasLength(1));

    app.container.read(appRouterProvider).go('/favorites');
    await settleDatabase(tester);
    await tester.longPress(find.text('Fini').first);
    await settleDatabase(tester);
    expect(find.text('Retiré des favoris : Fini'), findsOneWidget);
    expect(await ids(), isEmpty);

    await tester.tap(find.text('Annuler'));
    await settleDatabase(tester);
    expect(await ids(), hasLength(1));
    await app.dispose(tester);
  });
}
