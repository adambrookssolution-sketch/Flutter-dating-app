import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/datasource/couples_datasource.dart';

/// Riverpod state for the discovery feed filter panel.
///
/// Progressive adoption (PROJECT_OVERVIEW §5): only NEW screens use Riverpod.
/// Existing screens keep their `StatefulWidget` + `setState` patterns so we
/// don't rewrite battle-tested flows mid-project.
///
/// Per client decision on 2026-04-23 country/city filters were removed in
/// favour of pure geolocation-by-radius. The [centerLat] / [centerLng]
/// come from the device's current location (resolved by the feed screen)
/// and [radiusKm] is the only location knob the user sees.
///
/// As of the 2026-04-29 unification, [interests] is a single flat set
/// shared with registration and profile; visual grouping happens via
/// [InterestGroups]. [openToUnicorn] / [openToBull] are tri-state —
/// null means the filter is off.
class FiltersState {
  /// Hard floor for the geolocation radius — client spec 2026-04-20
  /// requires the feed to never return a window tighter than 5 km so
  /// users in rural areas always see at least something.
  static const double minRadiusKm = 5.0;

  final double? centerLat;
  final double? centerLng;
  final double radiusKm;
  final int? minAge;
  final int? maxAge;

  final Set<String> interests;

  /// Tri-state: null = off, true = require the same flag on the couple.
  /// We don't expose `false` because there's no use case for "show me
  /// couples NOT open to X".
  final bool? openToUnicorn;
  final bool? openToBull;

  // Travel Match constraints — picked from inside the filters panel per the
  // 2026-04-21 brief ("Travel Match dentro de los filtros").
  //
  // [travelDestinationId] matches a document ID in the `destinations`
  // collection; a couple's trip qualifies when its destination matches AND
  // the date ranges overlap (even by a single day).
  final String? travelDestinationId;
  final DateTime? travelFrom;
  final DateTime? travelTo;

  const FiltersState({
    this.centerLat,
    this.centerLng,
    double radiusKm = 200,
    this.minAge,
    this.maxAge,
    this.interests = const {},
    this.openToUnicorn,
    this.openToBull,
    this.travelDestinationId,
    this.travelFrom,
    this.travelTo,
  }) : radiusKm = radiusKm < minRadiusKm ? minRadiusKm : radiusKm;

  FiltersState copyWith({
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    int? minAge,
    int? maxAge,
    Set<String>? interests,
    bool? openToUnicorn,
    bool? openToBull,
    String? travelDestinationId,
    DateTime? travelFrom,
    DateTime? travelTo,
    bool clearAgeRange = false,
    bool clearTravel = false,
    bool clearOpenToUnicorn = false,
    bool clearOpenToBull = false,
  }) {
    return FiltersState(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusKm: radiusKm ?? this.radiusKm,
      minAge: clearAgeRange ? null : (minAge ?? this.minAge),
      maxAge: clearAgeRange ? null : (maxAge ?? this.maxAge),
      interests: interests ?? this.interests,
      openToUnicorn:
          clearOpenToUnicorn ? null : (openToUnicorn ?? this.openToUnicorn),
      openToBull:
          clearOpenToBull ? null : (openToBull ?? this.openToBull),
      travelDestinationId: clearTravel
          ? null
          : (travelDestinationId ?? this.travelDestinationId),
      travelFrom: clearTravel ? null : (travelFrom ?? this.travelFrom),
      travelTo: clearTravel ? null : (travelTo ?? this.travelTo),
    );
  }

  /// True when nothing is constraining the result set — lets the feed skip
  /// in-memory filtering entirely on cold start.
  bool get isEmpty =>
      minAge == null &&
      maxAge == null &&
      interests.isEmpty &&
      openToUnicorn == null &&
      openToBull == null &&
      centerLat == null &&
      travelDestinationId == null;

  CoupleFilters toDatasourceFilters() => CoupleFilters(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        interests: interests.toList(),
        minAge: minAge,
        maxAge: maxAge,
        openToUnicorn: openToUnicorn,
        openToBull: openToBull,
      );
}

class FiltersNotifier extends StateNotifier<FiltersState> {
  FiltersNotifier() : super(const FiltersState()) {
    // Client spec (2026-04-21): each user must have their own filter
    // session. Listening on Firebase auth state changes so the moment a
    // user signs out (or a different account signs in) we wipe the
    // current filters — otherwise the next login on the same device
    // would inherit the previous couple's selections.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) state = const FiltersState();
    });
  }

  StreamSubscription<User?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Sets the geolocation centre (typically from the device's current
  /// location). Radius is controlled separately via [setRadiusKm].
  void setLocation({required double lat, required double lng}) {
    state = state.copyWith(centerLat: lat, centerLng: lng);
  }

  void setRadiusKm(double km) => state = state.copyWith(radiusKm: km);

  void setAgeRange(int? min, int? max) {
    if (min == null && max == null) {
      state = state.copyWith(clearAgeRange: true);
    } else {
      state = state.copyWith(minAge: min, maxAge: max);
    }
  }

  void setTravelMatch({
    String? destinationId,
    DateTime? from,
    DateTime? to,
  }) {
    state = state.copyWith(
      travelDestinationId: destinationId,
      travelFrom: from,
      travelTo: to,
    );
  }

  void clearTravelMatch() => state = state.copyWith(clearTravel: true);

  /// Toggle a single interest chip on or off. Same call site is used for
  /// chips from any of the three visual groups — there is no separate
  /// state per group anymore.
  void toggleInterest(String tag) {
    final next = {...state.interests};
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    state = state.copyWith(interests: next);
  }

  /// Set or clear the "Open to Unicorn" filter. `value` of true keeps the
  /// filter on, `false` means we have no opinion and want every couple
  /// regardless of their flag — represented internally as null so we
  /// don't accidentally narrow the feed by toggling off.
  void setOpenToUnicorn(bool value) {
    state = state.copyWith(
      openToUnicorn: value ? true : null,
      clearOpenToUnicorn: !value,
    );
  }

  void setOpenToBull(bool value) {
    state = state.copyWith(
      openToBull: value ? true : null,
      clearOpenToBull: !value,
    );
  }

  void reset() => state = const FiltersState();
}

/// Global singleton of the filter state — `ref.watch(filtersProvider)` from
/// anywhere inside the feed tree.
final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>(
  (ref) => FiltersNotifier(),
);
