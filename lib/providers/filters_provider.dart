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
/// The `FiltersState` is effectively a typed view over [CoupleFilters]; the
/// notifier exposes granular mutation methods so widgets don't have to
/// rebuild the whole filter object for each toggle.
class FiltersState {
  final double? centerLat;
  final double? centerLng;
  final double radiusKm;
  final String? country;
  final String? city;
  final int? minAge;
  final int? maxAge;
  final Set<String> dynamics;
  final Set<String> experiencePreferences;
  final Set<String> interests;
  final double interestThreshold;

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
    this.radiusKm = 200,
    this.country,
    this.city,
    this.minAge,
    this.maxAge,
    this.dynamics = const {},
    this.experiencePreferences = const {},
    this.interests = const {},
    this.interestThreshold = 0.5,
    this.travelDestinationId,
    this.travelFrom,
    this.travelTo,
  });

  FiltersState copyWith({
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    String? country,
    String? city,
    int? minAge,
    int? maxAge,
    Set<String>? dynamics,
    Set<String>? experiencePreferences,
    Set<String>? interests,
    double? interestThreshold,
    String? travelDestinationId,
    DateTime? travelFrom,
    DateTime? travelTo,
    bool clearAgeRange = false,
    bool clearCity = false,
    bool clearCountry = false,
    bool clearTravel = false,
  }) {
    return FiltersState(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusKm: radiusKm ?? this.radiusKm,
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      minAge: clearAgeRange ? null : (minAge ?? this.minAge),
      maxAge: clearAgeRange ? null : (maxAge ?? this.maxAge),
      dynamics: dynamics ?? this.dynamics,
      experiencePreferences:
          experiencePreferences ?? this.experiencePreferences,
      interests: interests ?? this.interests,
      interestThreshold: interestThreshold ?? this.interestThreshold,
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
      country == null &&
      city == null &&
      minAge == null &&
      maxAge == null &&
      dynamics.isEmpty &&
      experiencePreferences.isEmpty &&
      interests.isEmpty &&
      centerLat == null &&
      travelDestinationId == null;

  CoupleFilters toDatasourceFilters() => CoupleFilters(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        dynamics: dynamics.toList(),
        experiencePreferences: experiencePreferences.toList(),
        interests: interests.toList(),
        interestThreshold: interestThreshold,
        country: country,
        city: city,
        minAge: minAge,
        maxAge: maxAge,
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

  void setLocation({
    required double lat,
    required double lng,
    required String city,
    required String country,
  }) {
    state = state.copyWith(
      centerLat: lat,
      centerLng: lng,
      city: city,
      country: country,
    );
  }

  void setCity(String? city) =>
      state = state.copyWith(city: city, clearCity: city == null);
  void setCountry(String? country) =>
      state = state.copyWith(country: country, clearCountry: country == null);

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

  void toggleDynamic(String tag) => _toggle(tag, 'dynamics');
  void toggleExperience(String tag) => _toggle(tag, 'experience');
  void toggleInterest(String tag) => _toggle(tag, 'interests');

  void _toggle(String tag, String bucket) {
    Set<String> current;
    switch (bucket) {
      case 'dynamics':
        current = {...state.dynamics};
        current.contains(tag) ? current.remove(tag) : current.add(tag);
        state = state.copyWith(dynamics: current);
      case 'experience':
        current = {...state.experiencePreferences};
        current.contains(tag) ? current.remove(tag) : current.add(tag);
        state = state.copyWith(experiencePreferences: current);
      case 'interests':
        current = {...state.interests};
        current.contains(tag) ? current.remove(tag) : current.add(tag);
        state = state.copyWith(interests: current);
    }
  }

  void reset() => state = const FiltersState();
}

/// Global singleton of the filter state — `ref.watch(filtersProvider)` from
/// anywhere inside the feed tree.
final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>(
  (ref) => FiltersNotifier(),
);
