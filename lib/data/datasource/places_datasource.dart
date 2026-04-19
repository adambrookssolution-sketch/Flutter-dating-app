import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:app/core/config/api_keys.dart';
import 'package:app/data/models/place_result.dart';

/// Thin wrapper around the Google Places REST API.
///
/// We hit the REST endpoints directly (no `google_places_flutter` /
/// `flutter_google_places_sdk` package) for three reasons:
/// 1. One fewer dependency to upgrade across Flutter versions.
/// 2. The session token discount works the same way via REST.
/// 3. Predicate UI is built locally, so we don't need a turnkey widget.
///
/// Cost control: Autocomplete is billed per session; we generate a fresh
/// session token in [PlacesAutocompleteSession.start] and pass it to every
/// keystroke + the final Place Details call. That collapses ~10 keystrokes
/// + 1 details call into a single billable session.
///
/// Privacy note: API responses contain place_id and formatted_address only —
/// no PII. We immediately drop everything except the fields needed by the
/// `couples` doc.
class PlacesDatasource {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Returns the platform-appropriate API key, or null when keys are still
  /// the placeholder values (dev fallback path).
  static String? _resolvedKey() {
    if (!ApiKeys.hasPlacesKey) return null;
    if (kIsWeb) return ApiKeys.googlePlacesAndroid; // web uses unrestricted
    if (Platform.isIOS) return ApiKeys.googlePlacesIos;
    return ApiKeys.googlePlacesAndroid;
  }

  /// Predict cities matching [query]. Returns at most 5 suggestions.
  /// Returns an empty list when the API key is missing or the request fails
  /// — callers should display the legacy fallback UI in that case.
  static Future<List<PlacePrediction>> autocomplete({
    required String query,
    required String sessionToken,
    String language = 'es',
  }) async {
    final key = _resolvedKey();
    if (key == null || query.trim().isEmpty) return const [];

    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
      'input': query,
      'types': '(cities)',
      'language': language,
      'sessiontoken': sessionToken,
      'key': key,
    });

    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
        return const [];
      }
      final preds = (json['predictions'] as List? ?? const []);
      return preds
          .whereType<Map<String, dynamic>>()
          .map(PlacePrediction.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Resolve a chosen prediction to lat/lng + country. Caller must pass the
  /// same [sessionToken] used during the matching autocomplete calls so
  /// Google bills it as a single session.
  ///
  /// Returns null on failure — caller should retry or surface a friendly
  /// error.
  static Future<PlaceResult?> details({
    required String placeId,
    required String sessionToken,
    String language = 'es',
  }) async {
    final key = _resolvedKey();
    if (key == null) return null;

    final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
      'place_id': placeId,
      'fields': 'geometry/location,address_component,name',
      'language': language,
      'sessiontoken': sessionToken,
      'key': key,
    });

    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final result = (json['result'] as Map<String, dynamic>?) ?? const {};
      final loc = (result['geometry']
              as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();

      final components =
          (result['address_components'] as List? ?? const []).cast();
      String country = '';
      String countryCode = '';
      String city = (result['name'] as String?) ?? '';
      for (final raw in components) {
        if (raw is! Map<String, dynamic>) continue;
        final types = (raw['types'] as List? ?? const []).cast<String>();
        if (types.contains('country')) {
          country = (raw['long_name'] as String?) ?? country;
          countryCode = (raw['short_name'] as String?) ?? countryCode;
        }
        if (types.contains('locality')) {
          city = (raw['long_name'] as String?) ?? city;
        }
      }

      return PlaceResult(
        city: city,
        country: country,
        countryCode: countryCode,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return null;
    }
  }
}

/// One row in the autocomplete dropdown.
class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> j) {
    final structured =
        (j['structured_formatting'] as Map<String, dynamic>?) ?? const {};
    return PlacePrediction(
      placeId: (j['place_id'] as String?) ?? '',
      mainText: (structured['main_text'] as String?) ??
          (j['description'] as String?) ??
          '',
      secondaryText:
          (structured['secondary_text'] as String?) ?? '',
    );
  }
}

/// Wraps a session token so multiple keystrokes share one billable session.
/// Spec: tokens are arbitrary strings up to 36 chars; UUID-style is fine.
class PlacesAutocompleteSession {
  final String token;

  PlacesAutocompleteSession._(this.token);

  factory PlacesAutocompleteSession.start() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    // 32 hex chars — under Google's 36-char ceiling, well above their 16-char floor.
    return PlacesAutocompleteSession._(hex);
  }
}
