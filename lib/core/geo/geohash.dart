// Pure-Dart GeoHash encoder. Mirrors the standard Niemeyer 2008 algorithm so
// strings are interoperable with `ngeohash` (used by Cloud Functions) and the
// `geoflutterfire_plus` query helpers.
//
// Precision 9 (~5m) is the project default — fine-grained enough for
// proximity matching while staying within Firestore's per-string-key
// performance comfort zone.

const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

class Geohash {
  const Geohash._();

  /// Encodes ([lat], [lng]) into a base32 geohash of length [precision].
  /// Returns an empty string if either coordinate is out of range — callers
  /// should treat that as "do not store geohash" rather than as a default.
  static String encode(double lat, double lng, {int precision = 9}) {
    if (lat < -90.0 || lat > 90.0) return '';
    if (lng < -180.0 || lng > 180.0) return '';
    if (precision < 1 || precision > 12) return '';

    double latLo = -90.0, latHi = 90.0;
    double lngLo = -180.0, lngHi = 180.0;
    final out = StringBuffer();
    int bit = 0;
    int ch = 0;
    bool even = true;

    while (out.length < precision) {
      if (even) {
        final mid = (lngLo + lngHi) / 2;
        if (lng >= mid) {
          ch |= 1 << (4 - bit);
          lngLo = mid;
        } else {
          lngHi = mid;
        }
      } else {
        final mid = (latLo + latHi) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit);
          latLo = mid;
        } else {
          latHi = mid;
        }
      }
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        out.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return out.toString();
  }
}
