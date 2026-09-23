import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/account/domain/account_service.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';

/// `null` quand l'application est compilée sans configuration serveur :
/// tout fonctionne alors hors ligne, en contenu gratuit.
final accountServiceProvider = Provider<AccountService?>((ref) => null);

/// E-mail du compte connecté, `null` sans compte.
final accountEmailProvider = FutureProvider<String?>(
  (ref) async => ref.watch(accountServiceProvider)?.email,
);

/// Droits actuels, calculés hors ligne depuis le jeton stocké.
final entitlementProvider = FutureProvider<Entitlement?>(
  (ref) async => ref.watch(accountServiceProvider)?.entitlements.current(),
);
