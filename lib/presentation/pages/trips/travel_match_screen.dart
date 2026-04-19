import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/data/models/trip.dart';
import 'package:app/presentation/widgets/secure_view.dart';

/// Shows couples whose trips overlap with this one on the same destination.
///
/// Queries the `findMatches` Cloud Function rather than hitting Firestore
/// directly — a `collectionGroup('trips')` query requires server-side
/// composite rules that bypass blocks/status filtering, easier to wrap in a
/// callable than to express in Security Rules.
class TravelMatchScreen extends StatefulWidget {
  final Trip trip;

  const TravelMatchScreen({super.key, required this.trip});

  @override
  State<TravelMatchScreen> createState() => _TravelMatchScreenState();
}

class _TravelMatchScreenState extends State<TravelMatchScreen> {
  Future<List<Map<String, dynamic>>>? _matches;

  @override
  void initState() {
    super.initState();
    _matches = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('findMatches');
    try {
      final resp = await callable.call<Map<String, dynamic>>({
        'tripId': widget.trip.id,
        'destinationId': widget.trip.destinationId,
        'startDate': widget.trip.startDate.toUtc().toIso8601String(),
        'endDate': widget.trip.endDate.toUtc().toIso8601String(),
      });
      final raw = resp.data['matches'] as List? ?? const [];
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } on FirebaseFunctionsException catch (e) {
      throw 'findMatches failed: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureView(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Travel match'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFF7E6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.trip.destination,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(widget.trip.startDate)} → ${_fmt(widget.trip.endDate)}',
                  style:
                      const TextStyle(color: Color(0xFF6B5500), fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _matches,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snap.error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No matches on this trip yet.\n\n'
                        'We will send a push the moment a couple registers '
                        'overlapping dates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFA4A4AA)),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final m = list[i];
                    final photo = m['photo'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photo != null ? NetworkImage(photo) : null,
                        child: photo == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text('${m['partnerA'] ?? ''} & ${m['partnerB'] ?? ''}'),
                      subtitle: Text(
                        '${m['city'] ?? ''}'
                        '${m['overlapDays'] != null ? " • ${m['overlapDays']} overlapping days" : ""}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  String _fmt(DateTime d) => DateFormat('d MMM y').format(d);
}
