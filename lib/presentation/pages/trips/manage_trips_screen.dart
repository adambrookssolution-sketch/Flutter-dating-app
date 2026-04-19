import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/data/datasource/trips_datasource.dart';
import 'package:app/data/models/trip.dart';
import 'package:app/presentation/pages/trips/add_trip_screen.dart';
import 'package:app/presentation/pages/trips/travel_match_screen.dart';

/// User's upcoming trips. Tapping a trip opens [TravelMatchScreen] showing
/// couples that match on destination + overlapping dates.
///
/// Past trips are hidden — the `start_date` filter in the datasource scopes
/// the stream to today-onward. To see historical trips we'd need an archive
/// view; out of scope for MVP.
class ManageTripsScreen extends StatelessWidget {
  const ManageTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage trips'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB31637),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add trip'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTripScreen()),
        ),
      ),
      body: StreamBuilder<List<Trip>>(
        stream: TripsDatasource.streamTrips(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final today = DateTime.now();
          final upcoming = all.where((t) => t.endDate.isAfter(today)).toList();
          if (upcoming.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flight_takeoff,
                        size: 48, color: Color(0xFFA4A4AA)),
                    SizedBox(height: 12),
                    Text(
                      'No trips yet.\nTap "Add trip" to get your first match.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA4A4AA)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: upcoming.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = upcoming[i];
              return ListTile(
                leading: const Icon(Icons.place, color: Color(0xFFB31637)),
                title: Text(t.destination,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${_fmt(t.startDate)} → ${_fmt(t.endDate)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFA4A4AA)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.group, color: Color(0xFFB31637)),
                      tooltip: 'See matches',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TravelMatchScreen(trip: t),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFA4A4AA)),
                      onPressed: () => _confirmDelete(context, uid, t),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelMatchScreen(trip: t),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('d MMM y').format(d);

  Future<void> _confirmDelete(
      BuildContext context, String uid, Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          'Cancels notifications to couples matched on "${trip.destination}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TripsDatasource.deleteTrip(uid, trip.id);
    }
  }
}
