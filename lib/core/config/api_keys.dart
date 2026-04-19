// LOCAL DEV STUB — REPLACE WITH REAL KEYS BEFORE TESTING PLACES AUTOCOMPLETE.
//
// This file is gitignored (see .gitignore). For new contributors:
// 1. Copy `api_keys.example.dart` to `api_keys.dart`
// 2. Paste keys from GCP Console (project `affinity-places`)
// 3. Never commit
//
// While the keys are placeholders, [PlacesAutocompleteField] short-circuits
// to its city-dropdown fallback so the UI still works in dev.

class ApiKeys {
  ApiKeys._();

  static const String googlePlacesAndroid = 'AIza_PASTE_ANDROID_KEY_HERE';
  static const String googlePlacesIos = 'AIza_PASTE_IOS_KEY_HERE';

  /// True when neither key has been replaced — callers should fall back to
  /// the legacy city dropdown so the app stays usable in dev.
  static bool get hasPlacesKey =>
      !googlePlacesAndroid.startsWith('AIza_PASTE') ||
      !googlePlacesIos.startsWith('AIza_PASTE');
}
