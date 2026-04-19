import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/data/datasource/destinations_datasource.dart';
import 'package:app/data/datasource/trips_datasource.dart';
import 'package:app/data/models/destination.dart';
import 'package:app/data/models/trip.dart';

/// Adds a new trip to `couples/{coupleId}/trips`. UI:
///   - Destination picker (modal sheet sourced from `destinations/*` or
///     the hard-coded fallback list)
///   - Date range picker (material showDateRangePicker)
///   - Save → writes doc → pops with `true`
class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  Destination? _destination;
  DateTimeRange? _range;
  bool _saving = false;
  String? _error;
  List<Destination>? _options;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final list = await DestinationsDatasource.getAll();
    if (!mounted) return;
    setState(() => _options = list);
  }

  Future<void> _pickDestination() async {
    final picked = await showModalBottomSheet<Destination>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFA4A4AA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pick a destination',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in (_options ?? const <Destination>[]))
                    ListTile(
                      leading: Icon(_iconFor(d.kind),
                          color: const Color(0xFFB31637)),
                      title: Text(d.name),
                      subtitle: Text(
                        d.country,
                        style:
                            const TextStyle(color: Color(0xFFA4A4AA)),
                      ),
                      onTap: () => Navigator.pop(context, d),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _destination = picked);
  }

  IconData _iconFor(DestinationKind kind) => switch (kind) {
        DestinationKind.resort => Icons.beach_access,
        DestinationKind.cruise => Icons.directions_boat,
        DestinationKind.event => Icons.celebration,
      };

  Future<void> _pickDates() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _save() async {
    if (_destination == null || _range == null) {
      setState(() => _error = 'Pick a destination and dates first.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TripsDatasource.addTrip(
        uid,
        Trip(
          id: 'tmp', // replaced server-side by addDoc auto-id
          destination: _destination!.name,
          destinationId: _destination!.id,
          startDate: _range!.start,
          endDate: _range!.end,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add trip'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Destination',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDestination,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFFA4A4AA)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _destination?.name ?? 'Pick destination',
                        style: TextStyle(
                          color: _destination == null
                              ? const Color(0xFFA4A4AA)
                              : const Color(0xFF333333),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dates',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDates,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFFA4A4AA)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _range == null
                            ? 'Pick dates'
                            : '${_fmt(_range!.start)} → ${_fmt(_range!.end)}',
                        style: TextStyle(
                          color: _range == null
                              ? const Color(0xFFA4A4AA)
                              : const Color(0xFF333333),
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        color: Color(0xFFA4A4AA), size: 18),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB31637),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(250),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('d MMM y').format(d);
}
