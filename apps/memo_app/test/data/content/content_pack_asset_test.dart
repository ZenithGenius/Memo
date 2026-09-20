import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_pack_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le paquet embarqué est complet et cohérent', () async {
    final pack = await const AssetContentPackSource().load();
    expect(pack.pictograms, hasLength(151));
    expect(pack.pictograms.map((p) => p.code).toSet(), hasLength(151));
    final categoryCodes = pack.categories.map((c) => c.code).toSet();
    for (final p in pack.pictograms) {
      expect(categoryCodes, contains(p.categoryCode));
      expect(p.labels['fr'], isNotNull, reason: p.code);
    }
    final beginners = pack.pictograms.where((p) => p.minLevel == 0).length;
    expect(beginners, greaterThanOrEqualTo(20));
  });
}
