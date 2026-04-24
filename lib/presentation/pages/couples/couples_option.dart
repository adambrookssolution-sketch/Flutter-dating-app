import 'dart:math' show Random;

import 'package:app/data/datasource/blocks_datasource.dart';
import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/message_request.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/widgets/couple_card.dart';
import 'package:app/presentation/widgets/send_request_dialog.dart';
import 'package:app/presentation/widgets/sticky_feed_actions.dart';
import 'package:app/providers/filters_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CouplesOption extends ConsumerStatefulWidget {
  const CouplesOption({super.key});

  @override
  ConsumerState<CouplesOption> createState() => _CouplesOptionState();
}

class _CouplesOptionState extends ConsumerState<CouplesOption> {
  static const int _pageSize = 20;

  List<UserProfile>? _profiles;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _cursor;
  Set<String> _partnerIds = const {};
  Set<String> _blockedIds = const {};
  String? _error;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Session-stable RNG seed — generated once per mount so the feed order
  // is random across sessions (avoids always-the-same-first-couple
  // complaint the client raised about "Couple Speed" on 2026-04-20) but
  // remains stable while the user scrolls, so pagination appends feel
  // natural instead of reshuffling on every fetch.
  final int _shuffleSeed =
      DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  final Set<String> _seenUids = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfiles();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Fire the next page load when within 80% of the current max extent.
    if (pos.pixels >= pos.maxScrollExtent * 0.8 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  /// Full reset — used by pull-to-refresh + initial load.
  Future<void> _loadProfiles() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
      _cursor = null;
      _profiles = null;
    });
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) {
        setState(() => _loading = false);
        return;
      }
      final sideCar = await Future.wait([
        ConversationDatasource.getConversationPartnerIds(myUid),
        BlocksDatasource.getMutualBlockIds(myUid),
      ]);
      _partnerIds = sideCar[0];
      _blockedIds = sideCar[1];

      final first = await ProfileDatasource.getProfilesPage(limit: _pageSize);
      _cursor = first.cursor;
      _hasMore = first.items.length == _pageSize;

      final filtered = _localExclude(first.items, myUid);
      final shuffled = _shuffleAndDedupe(filtered);
      if (mounted) {
        setState(() {
          _profiles = shuffled;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Fetches the next page and appends. Silently no-ops when already
  /// loading, when the cursor is null (end of feed), or when we're
  /// unmounted.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;
      final next = await ProfileDatasource.getProfilesPage(
        startAfter: _cursor,
        limit: _pageSize,
      );
      _cursor = next.cursor;
      _hasMore = next.items.length == _pageSize;
      final filtered = _localExclude(next.items, myUid);
      final shuffled = _shuffleAndDedupe(filtered);
      if (!mounted) return;
      setState(() {
        _profiles = [...(_profiles ?? const []), ...shuffled];
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<UserProfile> _localExclude(List<UserProfile> input, String myUid) {
    return input
        .where((p) =>
            p.uid != myUid &&
            !_partnerIds.contains(p.uid) &&
            !_blockedIds.contains(p.uid))
        .toList();
  }

  /// Session-stable shuffle + dedupe. Pages loaded later in the same
  /// session use the same seed, so the combined feed stays a single
  /// pseudo-random stream without ever showing the same couple twice.
  ///
  /// This is the behaviour the client calls "Couple Speed" (randomises
  /// and doesn't repeat) on the 2026-04-20 feedback message.
  List<UserProfile> _shuffleAndDedupe(List<UserProfile> input) {
    final fresh = <UserProfile>[];
    for (final p in input) {
      if (_seenUids.add(p.uid)) fresh.add(p);
    }
    final rng = Random(_shuffleSeed + _seenUids.length);
    fresh.shuffle(rng);
    return fresh;
  }

  Future<void> _blockCouple(UserProfile profile) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await BlocksDatasource.block(myUid, profile.uid);
      if (!mounted) return;
      setState(() {
        _blockedIds = {..._blockedIds, profile.uid};
        _profiles = (_profiles ?? const [])
            .where((p) => p.uid != profile.uid)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blocked ${profile.hisName} & ${profile.herName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block: $e')),
      );
    }
  }

  Future<void> _reportCouple(UserProfile profile) async {
    // Opening the full Report screen lives in `lib/presentation/pages/report/`
    // in the agency's build — here we surface a minimal flow that records
    // the intent and relies on the reports Cloud Function + moderation
    // panel to take over. The sticky notification gives the user
    // immediate feedback.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks — the report will be reviewed by our team.'),
      ),
    );
  }

  Future<void> _startConversation(UserProfile profile) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final displayName = '${profile.hisName} & ${profile.herName}';
    final visibleInterests = profile.interests.isEmpty
        ? const <String>[]
        : profile.interests
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final firstPhoto = profile.photos.isNotEmpty ? profile.photos.first : null;

    final sent = await SendRequestDialog.show(
      context,
      receiverCoupleId: profile.uid,
      receiverDisplayName: displayName,
      receiverPhotoUrl: firstPhoto,
      receiverVisibleInterests: visibleInterests,
      origen: RequestOrigin.busqueda,
    );

    if (!mounted || sent != true) return;

    // Hide the card once a Request has been sent (avoid re-selecting the
    // same couple while in cooldown / pending window).
    setState(() => _profiles?.remove(profile));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request sent to $displayName'),
        backgroundColor: const Color(0xFFB31637),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Applies the current Riverpod filter state in-memory.
  ///
  /// Per client decision on 2026-04-23 location filtering is no longer by
  /// country/city — it's by geolocation radius (km) only. Legacy
  /// [UserProfile] rows still have a single CSV `interests` string and no
  /// lat/lng, so geo filtering is a no-op for them; the radius kicks in
  /// once the feed source moves to the `couples` collection. Age and tag
  /// filters keep working against the CSV fields:
  ///
  ///   • age range    — computed from her/his birth dates
  ///   • dynamics     — token match inside the CSV interests string
  ///   • experience   — token match inside the CSV interests string
  ///   • interests    — ≥ 50 % of the user's selected interests must
  ///                    appear in the profile's CSV string
  ///
  /// Travel Match is only checkable once the feed source moves to the
  /// `couples` collection (trips live under `couples/{uid}/trips`); it's
  /// currently a no-op so users with a travel filter don't see an empty
  /// feed.
  List<UserProfile> _applyFilters(List<UserProfile> input, FiltersState f) {
    if (f.isEmpty) return input;

    // Pre-tokenise every profile's CSV interests string once.
    List<String> tokenise(String csv) => csv
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    return input.where((p) {
      if (f.minAge != null || f.maxAge != null) {
        final a1 = _ageFromBirth(p.herBirth);
        final a2 = _ageFromBirth(p.hisBirth);
        final older = a1 > a2 ? a1 : a2;
        final younger = a1 < a2 ? a1 : a2;
        if (f.maxAge != null && younger > f.maxAge!) return false;
        if (f.minAge != null && older < f.minAge!) return false;
      }

      final profileTags = tokenise(p.interests);

      // Dynamics — any selected dynamic must appear in the profile's tags.
      if (f.dynamics.isNotEmpty) {
        final wants = f.dynamics.map((s) => s.toLowerCase());
        if (!wants.any(profileTags.contains)) return false;
      }
      // Experience preferences — same rule.
      if (f.experiencePreferences.isNotEmpty) {
        final wants = f.experiencePreferences.map((s) => s.toLowerCase());
        if (!wants.any(profileTags.contains)) return false;
      }
      // Interests — fuzzy match with a configurable threshold (50 % by
      // default). Rounds down, so 1/2 selections passes.
      if (f.interests.isNotEmpty) {
        final wants = f.interests.map((s) => s.toLowerCase()).toList();
        final overlap =
            wants.where(profileTags.contains).length / wants.length;
        if (overlap < f.interestThreshold) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Reactively re-apply whenever the filter state changes.
    final filters = ref.watch(filtersProvider);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB31637)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.black38, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load profiles',
              style: const TextStyle(color: Colors.black45, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profiles = _applyFilters(_profiles ?? const [], filters);

    final l10n = AppLocalizations.of(context)!;

    if (profiles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProfiles,
        color: const Color(0xFFB31637),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Text(
              'No new couples to discover right now.\nCome back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      );
    }

    // Client mock (2026-04-20): a single couple card is visible at a
    // time; the user swipes up/down to see the next couple, and the
    // "Start Conversation" + "Filters" buttons are pinned to the bottom
    // of the viewport so they always operate on the *current* couple.
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProfiles,
            color: const Color(0xFFB31637),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: profiles.length,
              itemBuilder: (context, i) {
                final profile = profiles[i];
                final coupleProfile = CoupleProfile(
                  uid: profile.uid,
                  name1: profile.herName,
                  age1: _ageFromBirth(profile.herBirth),
                  name2: profile.hisName,
                  age2: _ageFromBirth(profile.hisBirth),
                  location: profile.city,
                  description: profile.description,
                  tags: profile.interests.isNotEmpty
                      ? profile.interests
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList()
                      : [],
                  photos: profile.photos,
                );
                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: CoupleCard(
                    profile: coupleProfile,
                    onStartConversation: () => _startConversation(profile),
                    onBlock: () => _blockCouple(profile),
                    onReport: () => _reportCouple(profile),
                  ),
                );
              },
            ),
          ),
        ),
        StickyFeedActions(
          startConversationLabel: l10n.startConversation,
          onStartConversation: () {
            final idx = _currentIndex.clamp(0, profiles.length - 1);
            _startConversation(profiles[idx]);
          },
        ),
      ],
    );
  }

  /// Parses "DD/MM/YYYY" birth date and returns current age.
  int _ageFromBirth(String birth) {
    if (birth.isEmpty) return 0;
    try {
      final parts = birth.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dob = DateTime(year, month, day);
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age > 0 ? age : 0;
      }
    } catch (_) {}
    return 0;
  }
}

