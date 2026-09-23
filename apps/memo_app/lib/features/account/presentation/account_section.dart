import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/account/data/auth_api.dart';
import 'package:memo/features/account/presentation/account_providers.dart';
import 'package:memo/features/caregiver/presentation/caregiver_gate.dart';
import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Compte de l'accompagnant dans les réglages. Masqué quand l'application
/// n'a pas de serveur configuré.
class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<Entitlement?> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    String? message;
    try {
      await action();
    } on AuthException catch (e) {
      message = authErrorText(l10n, e.error);
    } on LicenseApiException catch (e) {
      message = licenseErrorText(l10n, e.error);
    }
    ref
      ..invalidate(accountEmailProvider)
      ..invalidate(entitlementProvider);
    if (mounted) {
      setState(() {
        _busy = false;
        _message = message;
      });
    }
  }

  Future<void> _signIn() async {
    if (!await requireCaregiver(context, ref)) return;
    if (!mounted) return;
    final credentials = await showDialog<_Credentials>(
      context: context,
      builder: (_) => const _SignInDialog(),
    );
    if (credentials == null) return;
    final service = ref.read(accountServiceProvider)!;
    await _run(
      () => credentials.create
          ? service.signUp(credentials.email, credentials.password)
          : service.signIn(credentials.email, credentials.password),
    );
  }

  Future<void> _signOut() async {
    if (!await requireCaregiver(context, ref)) return;
    await _run(() async {
      await ref.read(accountServiceProvider)!.signOut();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(accountServiceProvider);
    if (service == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(accountEmailProvider).asData?.value;
    final entitlement = ref.watch(entitlementProvider).asData?.value;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final status = entitlement == null || !entitlement.isPremium
        ? l10n.accountFree
        : l10n.accountPremiumUntil(
            DateFormat.yMMMMd(locale).format(entitlement.validUntil!.toLocal()),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          email ?? l10n.accountSignedOut,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(status, style: const TextStyle(color: AppColors.mutedText)),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else if (email == null)
          FilledButton(onPressed: _signIn, child: Text(l10n.accountSignIn))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _run(service.sync),
                icon: const Icon(Icons.sync),
                label: Text(l10n.accountSync),
              ),
              OutlinedButton(
                onPressed: _signOut,
                child: Text(l10n.accountSignOut),
              ),
            ],
          ),
      ],
    );
  }
}

String authErrorText(AppLocalizations l10n, AuthError error) => switch (error) {
  AuthError.invalidCredentials => l10n.authInvalidCredentials,
  AuthError.emailTaken => l10n.authEmailTaken,
  AuthError.weakPassword => l10n.authWeakPassword,
  AuthError.confirmationRequired => l10n.authConfirmationRequired,
  AuthError.sessionExpired => l10n.authSessionExpired,
  AuthError.offline => l10n.networkOffline,
  AuthError.server => l10n.networkServer,
};

String licenseErrorText(AppLocalizations l10n, LicenseApiError error) =>
    switch (error) {
      LicenseApiError.noActiveSubscription => l10n.licenseNoSubscription,
      LicenseApiError.deviceLimitReached => l10n.licenseDeviceLimit,
      LicenseApiError.deviceRevoked => l10n.licenseDeviceRevoked,
      LicenseApiError.unauthorized => l10n.authSessionExpired,
      LicenseApiError.offline => l10n.networkOffline,
      LicenseApiError.server => l10n.networkServer,
    };

class _Credentials {
  const _Credentials(this.email, this.password, {required this.create});
  final String email;
  final String password;
  final bool create;
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog();

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid =>
      _email.text.contains('@') && _password.text.length >= (_create ? 10 : 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_create ? l10n.accountCreate : l10n.accountSignIn),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.accountEmail),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: [
                if (_create)
                  AutofillHints.newPassword
                else
                  AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: l10n.accountPassword,
                helperText: _create ? l10n.accountPasswordRule : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextButton(
              onPressed: () => setState(() => _create = !_create),
              child: Text(_create ? l10n.accountHaveOne : l10n.accountNoneYet),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(
                  _Credentials(_email.text, _password.text, create: _create),
                )
              : null,
          child: Text(_create ? l10n.accountCreate : l10n.accountSignIn),
        ),
      ],
    );
  }
}
