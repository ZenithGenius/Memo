import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/app.dart';
import 'package:memo/core/bootstrap.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';

import 'fakes.dart';

/// Application complète (contenu réel embarqué, base en mémoire, voix simulée)
/// avec un profil déjà créé.
class AppHarness {
  AppHarness._(this.db, this.container, this.speech);

  final AppDatabase db;
  final ProviderContainer container;
  final FakeSpeechService speech;

  static Future<AppHarness> start(
    WidgetTester tester, {
    Level level = Level.beginner,
  }) async {
    final speech = FakeSpeechService();
    final db = AppDatabase.forTesting();
    final container = (await tester.runAsync(
      () => createContainer(db: db, speech: speech),
    ))!;
    await tester.runAsync(() async {
      await container
          .read(profileRepositoryProvider)
          .create(name: 'T', type: ProfileType.child, level: level);
      // Attend que le profil actif soit diffusé avant d'afficher l'application.
      for (var i = 0; i < 100; i++) {
        if (container.read(activeProfileProvider).value != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MemoApp()),
    );
    await tester.pumpAndSettle();
    return AppHarness._(db, container, speech);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }
}
