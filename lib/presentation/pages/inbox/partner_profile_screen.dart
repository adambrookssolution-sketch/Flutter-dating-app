import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/data/datasource/trips_datasource.dart';
import 'package:app/data/models/trip_model.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/chat/chat_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:app/presentation/widgets/secure_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PartnerProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final bool? isMatch;
  final bool? isPending;

  const PartnerProfileScreen({
    super.key,
    required this.profile,
    this.isMatch,
    this.isPending,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  int _currentPhoto = 0;
  List<TripModel> _trips = [];
  bool _loadingTrips = true;
  bool _hasMatch = false;
  bool _isPending = false;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      debugPrint('PartnerProfile: [ERROR] No current user UID found.');
      return;
    }
    final otherUid = widget.profile.uid;
    debugPrint('PartnerProfile: Starting fetch for otherUid: $otherUid (My UID: $myUid)');

    try {
      debugPrint('PartnerProfile: Checking match between $myUid and $otherUid');
      // Only show trips if there's an active conversation (match)
      // If widget.isMatch is provided, use it instead of checking Firestore
      bool match = widget.isMatch ?? false;
      bool pending = widget.isPending ?? false;
      debugPrint('PartnerProfile: initial match value (from widget.isMatch): $match');

      if (widget.isMatch == null) {
        final partnerIds = await ConversationDatasource.getConversationPartnerIds(myUid);
        match = partnerIds.contains(otherUid);
        // If it exists in the conversation list, it is NOT pending.
        pending = false; 
        debugPrint('PartnerProfile: match check against ConversationDatasource: $match');
      }

      if (mounted) {
        setState(() {
          _hasMatch = match;
          _isPending = pending;
        });
      }

      if (!match) {
        debugPrint('PartnerProfile: No match found for $otherUid. Trips will not be displayed.');
        if (mounted) setState(() => _loadingTrips = false);
        return;
      }

      debugPrint('PartnerProfile: Match confirmed. Calling TripsDatasource.getTrips for: $otherUid');
      final trips = await TripsDatasource.getTrips(otherUid);
      debugPrint('PartnerProfile: Received ${trips.length} trips from TripsDatasource for $otherUid');
      
      for (var i = 0; i < trips.length; i++) {
        final t = trips[i];
        debugPrint('PartnerProfile: Trip[$i] -> ${t.city}, ${t.country} (${t.startDate} to ${t.endDate})');
      }

      if (mounted) {
        setState(() {
          _trips = trips;
          _loadingTrips = false;
        });
      }
    } catch (e, stack) {
      debugPrint('PartnerProfile: [EXCEPTION] Error fetching trips for $otherUid: $e');
      debugPrint('PartnerProfile: StackTrace: $stack');
      if (mounted) setState(() => _loadingTrips = false);
    }
  }

  int _ageFromBirth(String birth) {
    if (birth.isEmpty) return 0;
    try {
      final parts = birth.split('/');
      if (parts.length != 3) return 0;
      final dob = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age > 0 ? age : 0;
    } catch (_) {
      return 0;
    }
  }

  void _navigatePhoto(bool next) {
    final count =
        widget.profile.photos.isNotEmpty ? widget.profile.photos.length : 1;
    setState(() {
      _currentPhoto = next
          ? (_currentPhoto + 1) % count
          : (_currentPhoto - 1 + count) % count;
    });
  }

  /// "Start Conversation" button on the partner-profile detail screen.
  /// Agency-parity flow (client feedback 2026-05-17 #3): the user is
  /// pushed straight into ChatScreen with `pendingPartnerUid` when no
  /// match exists yet — the empty state offers three quick-starter
  /// bubbles and the first message becomes the request. When a match
  /// already exists we open the regular thread.
  Future<void> _openOrStartConversation() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final ids = [myUid, widget.profile.uid]..sort();
    final conversationId = ids.join('_');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversation: ConversationModel(
            conversationId: conversationId,
            name1: widget.profile.herName,
            name2: widget.profile.hisName,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            gradientIndex: conversationId.hashCode.abs(),
            photoUrl: widget.profile.photos.isNotEmpty
                ? widget.profile.photos.first
                : null,
            pendingPartnerUid: _hasMatch ? null : widget.profile.uid,
          ),
          otherProfile: widget.profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final l10n = AppLocalizations.of(context)!;
    final herAge = _ageFromBirth(profile.herBirth);
    final hisAge = _ageFromBirth(profile.hisBirth);
    final tags = profile.interests.isNotEmpty
        ? profile.interests
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = myUid == widget.profile.uid;

    return SecureView(
      child: Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: isSelf
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _loadingTrips ? null : _openOrStartConversation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB31637),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFB31637).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loadingTrips
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _hasMatch
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.forum_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasMatch
                                    ? l10n.openChat
                                    : l10n.startConversation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, profile),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildNamesSection(profile, herAge, hisAge),
                  const SizedBox(height: 14),
                  if (profile.city.isNotEmpty) ...[
                    _buildInfoRow(Icons.location_on_rounded, profile.city),
                    const SizedBox(height: 14),
                  ],
                  if (profile.herHeight.isNotEmpty ||
                      profile.hisHeight.isNotEmpty) ...[
                    _buildHeightsSection(l10n, profile),
                    const SizedBox(height: 20),
                  ],
                  if (profile.description.isNotEmpty) ...[
                    _buildSectionTitle(l10n.description),
                    const SizedBox(height: 8),
                    Text(
                      profile.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (tags.isNotEmpty) ...[
                    _buildSectionTitle(l10n.interests),
                    const SizedBox(height: 10),
                    _buildTags(tags),
                    const SizedBox(height: 24),
                  ],
                  if (_loadingTrips) ...[
                    _buildSectionTitle(l10n.scheduledTrips),
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB31637),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ] else if (_hasMatch) ...[
                    _buildSectionTitle(l10n.scheduledTrips),
                    const SizedBox(height: 10),
                    if (_trips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          l10n.noTripsScheduled,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                        ),
                      )
                    else
                      _buildTripsSection(),
                    const SizedBox(height: 40),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _askAboutTrip(TripModel trip, AppLocalizations l10n) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    
    final destination = trip.displayDestination;
    final dateStr = DateFormat('dd/MM/yyyy').format(trip.startDate);
    final initialMessage = l10n.tripMessageTemplate(destination, dateStr);

    final ids = [myUid, widget.profile.uid]..sort();
    final conversationId = ids.join('_');

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversation: ConversationModel(
            conversationId: conversationId,
            name1: widget.profile.herName,
            name2: widget.profile.hisName,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            gradientIndex: conversationId.hashCode.abs(),
            photoUrl: widget.profile.photos.isNotEmpty ? widget.profile.photos.first : null,
            pendingPartnerUid: _isPending ? widget.profile.uid : null,
          ),
          otherProfile: widget.profile,
          initialMessage: initialMessage,
        ),
      ),
    );
  }

  Widget _buildTripsSection() {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      children: _trips.map((trip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _askAboutTrip(trip, l10n),
              onLongPress: () => _askAboutTrip(trip, l10n),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.flight_takeoff_rounded,
                        color: Color(0xFFB31637), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.displayDestination,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fmt.format(trip.startDate)} – ${fmt.format(trip.endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFB31637), size: 20),
                      onPressed: () => _askAboutTrip(trip, l10n),
                      tooltip: l10n.askAboutTrip,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Sliver app bar with photo gallery ─────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context, UserProfile profile) {
    final top = MediaQuery.of(context).padding.top;
    final photoCount =
        profile.photos.isNotEmpty ? profile.photos.length : 1;

    return SliverAppBar(
      expandedHeight: 440,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: _BackButton(onPressed: () => Navigator.of(context).pop()),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTapUp: (d) {
            final width = MediaQuery.of(context).size.width;
            _navigatePhoto(d.localPosition.dx > width / 2);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhotoArea(profile),
              if (photoCount > 1)
                Positioned(
                  top: top + 12,
                  left: 64,
                  right: 16,
                  child: _buildPhotoIndicators(photoCount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea(UserProfile profile) {
    if (profile.photos.isNotEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Image.network(
          profile.photos[_currentPhoto % profile.photos.length],
          key: ValueKey(_currentPhoto),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFB31637),
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFEEEEEE),
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.black26, size: 48),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.favorite, size: 80, color: Colors.white24),
      ),
    );
  }

  Widget _buildPhotoIndicators(int count) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == _currentPhoto
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Content sections ───────────────────────────────────────────────────────

  Widget _buildNamesSection(UserProfile profile, int herAge, int hisAge) {
    final showAges = herAge > 0 || hisAge > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${profile.herName} & ${profile.hisName}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        if (showAges) ...[
          const SizedBox(height: 4),
          Text(
            '${herAge > 0 ? herAge : '?'} & ${hisAge > 0 ? hisAge : '?'} years',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB31637)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  Widget _buildHeightsSection(AppLocalizations l10n, UserProfile profile) {
    return Row(
      children: [
        if (profile.herHeight.isNotEmpty)
          Expanded(
            child: _HeightChip(
              label: l10n.herHeight,
              value: profile.herHeight,
            ),
          ),
        if (profile.herHeight.isNotEmpty && profile.hisHeight.isNotEmpty)
          const SizedBox(width: 12),
        if (profile.hisHeight.isNotEmpty)
          Expanded(
            child: _HeightChip(
              label: l10n.hisHeight,
              value: profile.hisHeight,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF222222),
      ),
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB31637).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFB31637).withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFB31637),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.black45,
      radius: 18,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _HeightChip extends StatelessWidget {
  final String label;
  final String value;
  const _HeightChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFA4A4AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
