import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';

/// Confirme une action dont l'effet ne se voit pas tout de suite : message
/// bref en bas de l'écran et vibration légère si les vibrations sont activées.
void confirmAction(
  BuildContext context,
  WidgetRef ref,
  String message, {
  SnackBarAction? action,
}) {
  final settings =
      ref.read(appSettingsProvider).asData?.value ?? AppSettings.defaults;
  if (settings.hapticsEnabled) HapticFeedback.lightImpact();
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
