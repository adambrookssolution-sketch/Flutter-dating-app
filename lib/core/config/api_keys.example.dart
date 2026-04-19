// Template for `lib/core/config/api_keys.dart` — copy this file, fill in the
// real keys, and DO NOT commit. The real file is gitignored.
//
// Source: each key is created in Google Cloud Console
// (project `affinity-places`, owner `affinitysocialclub@gmail.com`).
//
// See docs/PROGRESS_LOG.md "Week 0.1" for the full GCP setup walkthrough.

class ApiKeys {
  ApiKeys._();

  /// Restricted to Android package `com.affinitysocialclub.app` + SHA-1.
  static const String googlePlacesAndroid = 'AIza_PASTE_ANDROID_KEY_HERE';

  /// Restricted to iOS bundle id `com.affinitysocialclub.app`.
  static const String googlePlacesIos = 'AIza_PASTE_IOS_KEY_HERE';
}
