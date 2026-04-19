/// Calculated age range of the two partners — derived from their birth dates
/// at write-time so range queries don't have to recompute on every read.
///
/// Stored as `{ min, max }` to support filter slider queries
/// (e.g. `where age_range.min <= filter.max && age_range.max >= filter.min`).
class AgeRange {
  final int min;
  final int max;

  const AgeRange({required this.min, required this.max});

  Map<String, dynamic> toMap() => {'min': min, 'max': max};

  factory AgeRange.fromMap(Map<String, dynamic>? m) => AgeRange(
        min: (m?['min'] as num?)?.toInt() ?? 0,
        max: (m?['max'] as num?)?.toInt() ?? 0,
      );

  /// Computes the [AgeRange] from two `DD/MM/YYYY` birth strings.
  /// Returns `(0, 0)` if either string is malformed — caller should validate
  /// before relying on the result.
  factory AgeRange.fromBirths(String birthA, String birthB,
      {DateTime? today}) {
    final now = today ?? DateTime.now();
    final a = _ageFromDdmmyyyy(birthA, now);
    final b = _ageFromDdmmyyyy(birthB, now);
    if (a == null || b == null) return const AgeRange(min: 0, max: 0);
    return AgeRange(min: a < b ? a : b, max: a > b ? a : b);
  }

  static int? _ageFromDdmmyyyy(String s, DateTime today) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    int age = today.year - y;
    if (today.month < m || (today.month == m && today.day < d)) age--;
    return age < 0 ? null : age;
  }
}
