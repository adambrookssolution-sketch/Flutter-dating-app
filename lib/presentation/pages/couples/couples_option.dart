import 'package:app/data/datasource/blocks_datasource.dart';
import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/message_request.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/filters/filters_screen.dart';
import 'package:app/presentation/widgets/couple_card.dart';
import 'package:app/presentation/widgets/pineapple_filter_button.dart';
import 'package:app/presentation/widgets/send_request_dialog.dart';
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
      if (mounted) {
        setState(() {
          _profiles = filtered;
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
      if (!mounted) return;
      setState(() {
        _profiles = [...(_profiles ?? const []), ...filtered];
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
  /// Legacy [UserProfile] has no dynamics/experience/lat/lng fields, so the
  /// only filters that can be enforced here are city and age. The richer
  /// filters are a no-op against legacy docs — they start working once Week
  /// 3.2 ships the `Couple` feed source. That's acceptable: for the window
  /// where dev still reads `profiles/*`, users with filters set will
  /// effectively see everything; migrated users will see the richer set.
  List<UserProfile> _applyFilters(List<UserProfile> input, FiltersState f) {
    if (f.isEmpty) return input;
    return input.where((p) {
      if (f.city != null && f.city!.isNotEmpty && p.city != f.city) {
        return false;
      }
      if (f.minAge != null || f.maxAge != null) {
        final a1 = _ageFromBirth(p.herBirth);
        final a2 = _ageFromBirth(p.hisBirth);
        final older = a1 > a2 ? a1 : a2;
        final younger = a1 < a2 ? a1 : a2;
        if (f.maxAge != null && younger > f.maxAge!) return false;
        if (f.minAge != null && older < f.minAge!) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FiltersScreen()),
    );
    if (changed == true) setState(() {}); // re-applies the now-updated filters
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

    final activeFilterCount = _countActive(filters);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadProfiles,
          color: const Color(0xFFB31637),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: profiles.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        if (i >= profiles.length) {
          // Footer loader row while the next page is in flight.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB31637),
                ),
              ),
            ),
          );
        }
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 520,
              child: CoupleCard(
                profile: coupleProfile,
                onStartConversation: () => _startConversation(profile),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _startConversation(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB31637),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.25),
              ),
              child: Text(
                l10n.startConversation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
        ),
      ),
      // Pineapple filter button — pinned to the top-right of the feed per
      // the client's 2026-04-20 reference mock. Stays put when the list
      // scrolls because it lives in the outer Stack above the scroll view.
      Positioned(
        top: 8,
        right: 16,
        child: PineappleFilterButton(
          activeCount: activeFilterCount,
          onTap: _openFilters,
        ),
      ),
    ],
  );
  }

  int _countActive(FiltersState f) =>
      (f.city != null ? 1 : 0) +
      (f.country != null ? 1 : 0) +
      (f.minAge != null || f.maxAge != null ? 1 : 0) +
      f.dynamics.length +
      f.experiencePreferences.length +
      f.interests.length;

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

