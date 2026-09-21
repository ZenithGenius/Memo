import 'package:equatable/equatable.dart';

/// Réglages de l'appareil (par opposition aux réglages d'un profil).
class AppSettings extends Equatable {
  const AppSettings({this.speakEachWord = true, this.hapticsEnabled = true});

  /// Prononcer chaque mot dès qu'on le touche, avant la phrase entière :
  /// un retour immédiat pour les plus jeunes.
  final bool speakEachWord;

  /// Vibrations. À couper pour économiser la batterie.
  final bool hapticsEnabled;

  static const defaults = AppSettings();

  AppSettings copyWith({bool? speakEachWord, bool? hapticsEnabled}) =>
      AppSettings(
        speakEachWord: speakEachWord ?? this.speakEachWord,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );

  @override
  List<Object?> get props => [speakEachWord, hapticsEnabled];
}

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();
  Future<void> setSpeakEachWord({required bool value});
  Future<void> setHapticsEnabled({required bool value});
}
