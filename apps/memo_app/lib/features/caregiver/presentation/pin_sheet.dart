import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';
import 'package:memo/features/caregiver/presentation/adult_check_dialog.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_pad.dart';
import 'package:memo/l10n/app_localizations.dart';

enum _Step { enter, create, confirm }

/// Saisie du code accompagnant, ou création s'il n'existe pas encore.
/// Se ferme avec `true` quand le mode accompagnant est déverrouillé.
class PinSheet extends ConsumerStatefulWidget {
  const PinSheet({super.key});

  @override
  ConsumerState<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<PinSheet> {
  _Step? _step;
  String _digits = '';
  String? _firstEntry;
  String? _message;
  bool _busy = false;

  /// Fin du blocage après trop d'essais. Tant qu'elle n'est pas atteinte, le
  /// pavé est désactivé et l'attente restante décompte chaque seconde.
  DateTime? _lockedUntil;
  Timer? _lockTicker;

  @override
  void initState() {
    super.initState();
    _decideStep();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  int get _lockSecondsLeft {
    final until = _lockedUntil;
    if (until == null) return 0;
    final ms = until.difference(ref.read(caregiverPinServiceProvider).now());
    return ms.isNegative ? 0 : (ms.inMilliseconds / 1000).ceil();
  }

  void _startLock(Duration remaining) {
    _lockedUntil = ref.read(caregiverPinServiceProvider).now().add(remaining);
    // Annoncé une fois : la zone de message n'est pas relue à chaque seconde.
    SemanticsService.sendAnnouncement(
      View.of(context),
      AppLocalizations.of(context).pinLocked(_lockSecondsLeft),
      Directionality.of(context),
    );
    _lockTicker?.cancel();
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_lockSecondsLeft == 0) {
          timer.cancel();
          _lockedUntil = null;
        }
      });
    });
  }

  Future<void> _decideStep() async {
    final isSet = await ref.read(caregiverPinServiceProvider).isSet;
    if (mounted) setState(() => _step = isSet ? _Step.enter : _Step.create);
  }

  void _onDigit(String d) {
    if (_busy || _lockedUntil != null || _digits.length >= PinDots.length) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _digits += d;
      _message = null;
    });
    if (_digits.length == PinDots.length) _submit();
  }

  void _onDelete() {
    if (_busy || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(caregiverPinServiceProvider);
    final entered = _digits;
    setState(() => _busy = true);

    String? message;
    switch (_step!) {
      case _Step.enter:
        final result = await service.verify(entered);
        switch (result) {
          case PinAccepted():
            return _unlock();
          case PinRejected(:final attemptsLeft):
            message = l10n.pinWrong(attemptsLeft);
          case PinLocked(:final remaining):
            _startLock(remaining);
        }
      case _Step.create:
        try {
          // La force du code est vérifiée à la confirmation ; ici on retient.
          if (_isWeak(entered)) throw const WeakPinException();
          _firstEntry = entered;
          if (!mounted) return;
          setState(() {
            _step = _Step.confirm;
            _digits = '';
            _busy = false;
          });
          return;
        } on WeakPinException {
          message = l10n.pinWeak;
        }
      case _Step.confirm:
        if (entered != _firstEntry) {
          message = l10n.pinMismatch;
          _firstEntry = null;
          if (!mounted) return;
          setState(() {
            _step = _Step.create;
            _digits = '';
            _message = message;
            _busy = false;
          });
          return;
        }
        await service.setPin(entered);
        return _unlock();
    }

    unawaited(HapticFeedback.heavyImpact());
    if (!mounted) return;
    setState(() {
      _digits = '';
      _message = message;
      _busy = false;
    });
  }

  /// Code oublié : contrôle adulte, puis création d'un nouveau code.
  /// Les données ne sont pas touchées.
  Future<void> _forgot() async {
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => const AdultCheckDialog(),
    );
    if (!(passed ?? false)) return;
    await ref.read(caregiverPinServiceProvider).reset();
    if (!mounted) return;
    setState(() {
      _step = _Step.create;
      _digits = '';
      _message = null;
    });
  }

  bool _isWeak(String pin) =>
      RegExp(r'^(\d)\1{3}$').hasMatch(pin) ||
      const {'1234', '4321', '0123', '3210'}.contains(pin);

  void _unlock() {
    ref.read(caregiverSessionProvider.notifier).unlock();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _step;
    final title = switch (step) {
      _Step.enter => l10n.pinEnterTitle,
      _Step.create => l10n.pinCreateTitle,
      _Step.confirm => l10n.pinConfirmTitle,
      null => '',
    };
    final locked = _lockSecondsLeft;
    final message = locked > 0 ? l10n.pinLocked(locked) : _message;
    final hint = switch (step) {
      _Step.enter => l10n.pinEnterHint,
      _Step.create => l10n.pinCreateHint,
      _Step.confirm => l10n.pinConfirmHint,
      null => '',
    };
    // Défilable : sur un petit écran (5 pouces) le pavé ne tient pas toujours
    // en entier avec le titre et le message.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: step == null
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: l10n.pinDigitsEntered(_digits.length),
                    excludeSemantics: true,
                    child: PinDots(filled: _digits.length),
                  ),
                  SizedBox(
                    height: 44,
                    child: Center(
                      child: message == null
                          ? null
                          : Semantics(
                              liveRegion: locked == 0,
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                  PinPad(
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    enabled: !_busy && locked == 0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (step == _Step.enter)
                        TextButton(
                          onPressed: _busy ? null : _forgot,
                          child: Text(l10n.pinForgot),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.pinCancel),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
