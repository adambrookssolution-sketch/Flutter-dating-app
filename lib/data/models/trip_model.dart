import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String destination;
  // Kept for backward compatibility with existing Firestore documents.
  final String country;
  final String city;
  final DateTime startDate;
  final DateTime endDate;

  const TripModel({
    required this.id,
    this.destination = '',
    this.country = '',
    this.city = '',
    required this.startDate,
    required this.endDate,
  });

  /// Returns the display label: the destination name if set, otherwise
  /// falls back to the legacy "country, city" format.
  String get displayDestination {
    if (destination.isNotEmpty) return destination;
    if (country.isNotEmpty && city.isNotEmpty) return '$country, $city';
    if (country.isNotEmpty) return country;
    return city;
  }

  Map<String, dynamic> toMap() => {
        'destination': destination,
        'country': country,
        'city': city,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
      };

  factory TripModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data()!;
    return TripModel(
      id: doc.id,
      destination: m['destination'] as String? ?? '',
      country: m['country'] as String? ?? '',
      city: m['city'] as String? ?? '',
      startDate: (m['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (m['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
