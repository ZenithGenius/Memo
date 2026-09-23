import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/app.dart';
import 'package:memo/core/bootstrap.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';

import 'fakes.dart';

/// Application complète (contenu réel embarqué, base en mémoire, voix simulée)
/// avec un profil déjà créé.
class AppHarness {
  AppHarness._(this.db, this.container, this.speech, this.secureStore);

  final AppDatabase db;
  final ProviderContainer container;
  final FakeSpeechService speech;
  final InMemorySecureStore secureStore;

  /// Horloge du service de code : avancer cette date simule le temps qui passe.
  static DateTime clock = DateTime.utc(2026, 9, 22, 10);

  static Future<AppHarness> start(
    WidgetTester tester, {
    Level level = Level.beginner,
    String name = 'T',
    List<Override> Function(AppDatabase db, InMemorySecureStore store)?
    overrides,
  }) async {
    // Taille d'un téléphone : sur la fenêtre de test par défaut, des éléments
    // resteraient hors de l'écran et ne recevraient pas les touchers.
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final speech = FakeSpeechService();
    final db = AppDatabase.forTesting();
    final secureStore = InMemorySecureStore();
    clock = DateTime.utc(2026, 9, 22, 10);
    final container = (await tester.runAsync(
      () => createContainer(
        db: db,
        speech: speech,
        secureStore: secureStore,
        now: () => clock,
        // Abonné : le contenu payant est visible.
        overrides: [
          premiumUnlockedProvider.overrideWithValue(true),
          ...?overrides?.call(db, secureStore),
        ],
      ),
    ))!;
    await tester.runAsync(() async {
      await ContentImporter(db).importIfNeeded(
        await loadPremiumPack(),
        slot: ContentImporter.premiumSlot,
      );
      await container
          .read(profileRepositoryProvider)
          .create(name: name, type: ProfileType.child, level: level);
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
    return AppHarness._(db, container, speech, secureStore);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }
}

/// Laisse les écritures et les flux de la base se propager avant de redessiner :
/// ils avancent en temps réel, pas dans le temps simulé des tests. Alterne
/// attente réelle et images tant qu'un indicateur de chargement est visible.
Future<void> settleDatabase(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final loading = find
        .byType(CircularProgressIndicator)
        .evaluate()
        .isNotEmpty;
    // Au moins trois tours : une écriture puis sa notification puis le
    // rechargement de l'écran ne tiennent pas dans un seul.
    if (i >= 2 && !loading && !tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle();
}

/// Paquet payant tel que servi par la fonction premium-pack.
Future<ContentPack> loadPremiumPack() async => ContentPack.fromJson(
  jsonDecode(
        await File(
          '../../backend/supabase/functions/premium-pack/pack.json',
        ).readAsString(),
      )
      as Map<String, Object?>,
);
