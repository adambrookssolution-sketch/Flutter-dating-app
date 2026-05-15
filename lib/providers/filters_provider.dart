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

  // Dynamics-split filter (client design 2026-05-12): what THIS couple is
  // looking for in the OTHER couple. Mirrors the profile's self fields
  // but lives only in feed state — never written back to the couple doc
  // from here (the doc's looking_for_* fields are written by the filter
  // commit handler so they survive cross-device sessions).
  // Multi-select since client feedback 2026-05-15 #6 — Type of
  // Interaction can pick multiple values both for self and for the
  // looking-for filter.
  final Set<String> lookingForInteraction;
  final Set<String> lookingForExperience;
  final Set<String> lookingForInterests;
  final String lookingForHerIdentity;
  final String lookingForHimIdentity;
  final String lookingForHerRole;
  final String lookingForHimRole;
  final bool lookingForUnicorn;
  final bool lookingForBull;

  // Travel Match constraints — picked from inside the filters panel per the
  // 2026-04-21 brief ("Travel Match dentro de los filtros").
  //
  // [travelDestinationId] matches a document ID in the `destinations`
  // collection; a couple's trip qualifies when its destination matches AND
  // the date ranges overlap (even by a single day).
  final String? travelDestinationId;
  final DateTime? travelFrom;
  final DateTime? travelTo;

  /// Client request 2026-04-30 (#4): allow filtering the feed by the
  /// country the couple registered from. ISO 3166-1 alpha-2 ("MX", "ES",
  /// "AR"). Null means "any country".
  final String? countryCode;

  /// Client request 2026-04-30 (#5): hide explicit posts from the feed
  /// unless the user explicitly opts in. Defaults to false.
  final bool showExplicit;

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
    this.countryCode,
    this.showExplicit = false,
    this.lookingForInteraction = const {},
    this.lookingForExperience = const {},
    this.lookingForInterests = const {},
    this.lookingForHerIdentity = '',
    this.lookingForHimIdentity = '',
    this.lookingForHerRole = '',
    this.lookingForHimRole = '',
    this.lookingForUnicorn = false,
    this.lookingForBull = false,
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
    String? countryCode,
    bool? showExplicit,
    Set<String>? lookingForInteraction,
    Set<String>? lookingForExperience,
    Set<String>? lookingForInterests,
    String? lookingForHerIdentity,
    String? lookingForHimIdentity,
    String? lookingForHerRole,
    String? lookingForHimRole,
    bool? lookingForUnicorn,
    bool? lookingForBull,
    bool clearAgeRange = false,
    bool clearTravel = false,
    bool clearOpenToUnicorn = false,
    bool clearOpenToBull = false,
    bool clearCountry = false,
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
      countryCode: clearCountry ? null : (countryCode ?? this.countryCode),
      showExplicit: showExplicit ?? this.showExplicit,
      lookingForInteraction:
          lookingForInteraction ?? this.lookingForInteraction,
      lookingForExperience:
          lookingForExperience ?? this.lookingForExperience,
      lookingForInterests:
          lookingForInterests ?? this.lookingForInterests,
      lookingForHerIdentity:
          lookingForHerIdentity ?? this.lookingForHerIdentity,
      lookingForHimIdentity:
          lookingForHimIdentity ?? this.lookingForHimIdentity,
      lookingForHerRole: lookingForHerRole ?? this.lookingForHerRole,
      lookingForHimRole: lookingForHimRole ?? this.lookingForHimRole,
      lookingForUnicorn: lookingForUnicorn ?? this.lookingForUnicorn,
      lookingForBull: lookingForBull ?? this.lookingForBull,
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
      travelDestinationId == null &&
      countryCode == null &&
      !showExplicit &&
      lookingForInteraction.isEmpty &&
      lookingForExperience.isEmpty &&
      lookingForInterests.isEmpty &&
      lookingForHerIdentity.isEmpty &&
      lookingForHimIdentity.isEmpty &&
      lookingForHerRole.isEmpty &&
      lookingForHimRole.isEmpty &&
      !lookingForUnicorn &&
      !lookingForBull;

  CoupleFilters toDatasourceFilters() => CoupleFilters(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        interests: interests.toList(),
        minAge: minAge,
        maxAge: maxAge,
        openToUnicorn: openToUnicorn,
        openToBull: openToBull,
        countryCode: countryCode,
        showExplicit: showExplicit,
        lookingForInteraction: lookingForInteraction.toList(),
        lookingForExperience: lookingForExperience.toList(),
        lookingForInterests: lookingForInterests.toList(),
        lookingForHerIdentity: lookingForHerIdentity,
        lookingForHimIdentity: lookingForHimIdentity,
        lookingForHerRole: lookingForHerRole,
        lookingForHimRole: lookingForHimRole,
        lookingForUnicorn: lookingForUnicorn,
        lookingForBull: lookingForBull,
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

  /// Set or clear the country filter. Null/empty clears it.
  void setCountryCode(String? code) {
    if (code == null || code.isEmpty) {
      state = state.copyWith(clearCountry: true);
    } else {
      state = state.copyWith(countryCode: code.toUpperCase());
    }
  }

  /// Toggle the explicit-content feed view.
  void setShowExplicit(bool value) {
    state = state.copyWith(showExplicit: value);
  }

  // ── Dynamics-split (2026-05-12) ─────────────────────────────────────────

  void toggleLookingForInteraction(String value) {
    final next = {...state.lookingForInteraction};
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    state = state.copyWith(lookingForInteraction: next);
  }

  void toggleLookingForExperience(String value) {
    final next = {...state.lookingForExperience};
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    state = state.copyWith(lookingForExperience: next);
  }

  void toggleLookingForInterest(String value) {
    final next = {...state.lookingForInterests};
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    state = state.copyWith(lookingForInterests: next);
  }

  void setLookingForHerIdentity(String value) {
    state = state.copyWith(lookingForHerIdentity: value);
  }

  void setLookingForHimIdentity(String value) {
    state = state.copyWith(lookingForHimIdentity: value);
  }

  void setLookingForHerRole(String value) {
    state = state.copyWith(lookingForHerRole: value);
  }

  void setLookingForHimRole(String value) {
    state = state.copyWith(lookingForHimRole: value);
  }

  void setLookingForUnicorn(bool value) {
    state = state.copyWith(lookingForUnicorn: value);
  }

  void setLookingForBull(bool value) {
    state = state.copyWith(lookingForBull: value);
  }

  void reset() => state = const FiltersState();
}

/// Global singleton of the filter state — `ref.watch(filtersProvider)` from
/// anywhere inside the feed tree.
final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>(
  (ref) => FiltersNotifier(),
);
