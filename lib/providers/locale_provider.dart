import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable app locale, persisted in SharedPreferences.
///
/// `null` means "follow the device locale" (the default). The Settings
/// screen lets the user pin to Spanish or English explicitly.
///
/// Used in two places:
///   1. `MaterialApp.locale` so the user's choice overrides the OS locale.
///   2. The matchmaking query, to bias the feed toward couples who speak
///      the same language (server-side filter on `Couple.languages`).
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  static const _kKey = 'app_locale';
  final SharedPreferences _prefs;

  static Locale? _load(SharedPreferences prefs) {
    final code = prefs.getString(_kKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(_kKey);
    } else {
      await _prefs.setString(_kKey, locale.languageCode);
    }
  }
}

/// Bootstrapped in `main.dart` after `SharedPreferences.getInstance()`.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('inject in main.dart with overrides'),
);

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(ref.watch(sharedPrefsProvider)),
);
