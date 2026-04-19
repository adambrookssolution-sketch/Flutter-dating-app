import 'package:app/core/geo/geohash.dart';

/// Resolved location chosen from the Places autocomplete UI. Carries
/// everything the `couples` document needs for filtering + Travel Match
/// queries, so the caller doesn't have to make a second Geocoding call.
class PlaceResult {
  final String city;
  final String country;
  final String countryCode; // ISO 3166-1 alpha-2
  final double lat;
  final double lng;

  const PlaceResult({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.lat,
    required this.lng,
  });

  String get geohash => Geohash.encode(lat, lng, precision: 9);

  String get displayLabel =>
      country.isEmpty ? city : '$city, $country';

  /// Flat (cloud_firestore-free) representation suitable for direct
  /// Firestore writes. Datasources also synthesise a nested `geo` map
  /// (containing GeoPoint + geohash) for `geoflutterfire_plus` queries —
  /// see [CouplesDatasource.updateCouple].
  Map<String, dynamic> toCoupleFields() => {
        'city': city,
        'country': country,
        'country_code': countryCode,
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
      };
}
