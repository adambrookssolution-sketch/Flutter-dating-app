import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
///
/// Layout note (2026-04-23 client feedback): the "Add trip" action and the
/// "Explore More Trips" partner-travel CTA sit side-by-side in a fixed
/// bottom bar. Previously Add trip lived in a FloatingActionButton in the
/// bottom-right corner, which overlapped the new partner CTA and cut off
/// its label. Merging both into a single row keeps each action fully
/// visible regardless of list length.
class ManageTripsScreen extends StatelessWidget {
  const ManageTripsScreen({super.key});

  /// Partner travel-agency link surfaced via the "Explore More Trips"
  /// sticky CTA. Per client decision 2026-04-23 the concrete URL is
  /// defined later; until then the button opens this placeholder and
  /// falls back to a snackbar if `url_launcher` can't handle it.
  static const String _exploreMoreUrl =
      'https://affinitysocialclub.com/trips';

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

          final listChild = upcoming.isEmpty
              ? const _EmptyTripsState()
              : ListView.separated(
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = upcoming[i];
                    return ListTile(
                      leading:
                          const Icon(Icons.place, color: Color(0xFFB31637)),
                      title: Text(t.destination,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${_fmt(t.startDate)} → ${_fmt(t.endDate)}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFA4A4AA)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group,
                                color: Color(0xFFB31637)),
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

          return Column(
            children: [
              Expanded(child: listChild),
              _TripsBottomBar(
                onAddTrip: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTripScreen(),
                  ),
                ),
                onExploreMore: () => _openExploreMore(context),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('d MMM y').format(d);

  Future<void> _openExploreMore(BuildContext context) async {
    final uri = Uri.tryParse(_exploreMoreUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open partner travel site."),
        ),
      );
    }
  }

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

class _EmptyTripsState extends StatelessWidget {
  const _EmptyTripsState();

  @override
  Widget build(BuildContext context) {
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
}

/// Bottom action bar that stacks "Explore More Trips" and "Add trip" so
/// neither clips the other.
///
/// Explore More Trips gets the wider slot because its label is longer; Add
/// trip is a compact filled pill on the right so the primary/secondary
/// visual hierarchy is clear (filled = primary action).
class _TripsBottomBar extends StatelessWidget {
  const _TripsBottomBar({
    required this.onAddTrip,
    required this.onExploreMore,
  });

  final VoidCallback onAddTrip;
  final VoidCallback onExploreMore;

  static const Color _burgundy = Color(0xFFB31637);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEDEDED), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onExploreMore,
                  icon: const Icon(Icons.travel_explore,
                      color: _burgundy, size: 20),
                  label: const Text(
                    'Explore More Trips',
                    style: TextStyle(
                      color: _burgundy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _burgundy, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAddTrip,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Add trip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _burgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
