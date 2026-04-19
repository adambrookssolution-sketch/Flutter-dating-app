import 'package:cloud_firestore/cloud_firestore.dart';

/// A planned trip to a lifestyle resort/cruise. Stored as a subcollection
/// `couples/{coupleId}/trips/{tripId}` so per-couple queries are cheap.
///
/// Travel Match logic (Week 3): two couples match when their trips share the
/// same [destinationId] AND their [startDate]/[endDate] ranges overlap by at
/// least one day.
class Trip {
  final String id;
  final String destination; // human-readable name, denormalised for display
  final String destinationId; // FK to `destinations/{id}`
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;

  const Trip({
    required this.id,
    required this.destination,
    required this.destinationId,
    required this.startDate,
    required this.endDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'destination': destination,
        'destination_id': destinationId,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'created_at': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory Trip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Trip(
      id: doc.id,
      destination: (m['destination'] as String?) ?? '',
      destinationId: (m['destination_id'] as String?) ?? '',
      startDate:
          (m['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (m['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (m['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// True when this trip's date range overlaps with [other] by >= 1 day.
  /// Symmetric: a.overlapsWith(b) == b.overlapsWith(a).
  bool overlapsWith(Trip other) {
    return startDate.isBefore(other.endDate.add(const Duration(days: 1))) &&
        other.startDate.isBefore(endDate.add(const Duration(days: 1)));
  }
}
