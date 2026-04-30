import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/settings/delete_account_screen.dart';
import 'package:app/providers/locale_provider.dart';

/// Settings hub. Currently contains the two privacy-critical entries
/// (Account Deletion, future password change). Other items will land here
/// over Weeks 2-4: 2FA toggle, blocked list shortcut, etc.
///
/// Apple App Store explicitly requires Account Deletion to be reachable in
/// no more than 3 taps from the main navigation. The path here is:
/// Profile tab → Account Settings → Delete Account → confirmation.
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  String _localeLabel(AppLocalizations l10n, Locale? locale) {
    if (locale == null) return l10n.languageOptionSystem;
    if (locale.languageCode == 'en') return l10n.languageOptionEnglish;
    if (locale.languageCode == 'es') return l10n.languageOptionSpanish;
    return locale.languageCode;
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(localeProvider);
    final picked = await showModalBottomSheet<_LocaleChoice>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.languageSettingTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final choice in _LocaleChoice.values)
              RadioListTile<_LocaleChoice>(
                value: choice,
                groupValue: _LocaleChoice.fromLocale(current),
                onChanged: (v) => Navigator.pop(sheetCtx, v),
                activeColor: const Color(0xFFB01030),
                title: Text(switch (choice) {
                  _LocaleChoice.system => l10n.languageOptionSystem,
                  _LocaleChoice.english => l10n.languageOptionEnglish,
                  _LocaleChoice.spanish => l10n.languageOptionSpanish,
                }),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).setLocale(picked.toLocale());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSettingsTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.languageSettingTitle),
            subtitle: Text(_localeLabel(l10n, locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref, l10n),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.changePassword),
            subtitle: Text(l10n.comingSoon),
            enabled: false,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(l10n.changeEmail),
            subtitle: Text(l10n.comingSoon),
            enabled: false,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DeleteAccountScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LocaleChoice {
  system,
  english,
  spanish;

  static _LocaleChoice fromLocale(Locale? locale) {
    if (locale == null) return _LocaleChoice.system;
    if (locale.languageCode == 'es') return _LocaleChoice.spanish;
    return _LocaleChoice.english;
  }

  Locale? toLocale() => switch (this) {
        _LocaleChoice.system => null,
        _LocaleChoice.english => const Locale('en'),
        _LocaleChoice.spanish => const Locale('es'),
      };
}
