import 'dart:async';

import 'package:memo/features/settings/domain/app_settings.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings initial = AppSettings.defaults])
    : _current = initial;

  AppSettings _current;
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> setSpeakEachWord({required bool value}) async {
    _current = _current.copyWith(speakEachWord: value);
    _controller.add(_current);
  }

  @override
  Future<void> setHapticsEnabled({required bool value}) async {
    _current = _current.copyWith(hapticsEnabled: value);
    _controller.add(_current);
  }
}
