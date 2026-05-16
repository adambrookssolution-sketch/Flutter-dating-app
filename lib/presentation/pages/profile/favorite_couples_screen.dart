import 'package:app/data/datasource/favorite_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/pages/chat/chat_screen.dart';
import 'package:app/presentation/pages/inbox/partner_profile_screen.dart';
import 'package:app/presentation/widgets/conversation_row.dart';
import 'package:app/presentation/widgets/couple_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteCouplesScreen extends StatefulWidget {
  const FavoriteCouplesScreen({super.key});

  @override
  State<FavoriteCouplesScreen> createState() => _FavoriteCouplesScreenState();
}

class _FavoriteCouplesScreenState extends State<FavoriteCouplesScreen> {
  List<UserProfile>? _favorites;
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) {
        setState(() => _loading = false);
        return;
      }
      final ids = await FavoriteDatasource.getFavoriteIds(myUid);
      final profiles = await Future.wait(
        ids.map((id) => ProfileDatasource.getProfile(id)),
      );
      if (mounted) {
        setState(() {
          _favorites = profiles.whereType<UserProfile>().toList();
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

  Future<void> _confirmRemoveFavorite(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFavorite),
        content: Text(l10n.removeFavoriteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.removeFavorite,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _favorites?.remove(profile));
    try {
      await FavoriteDatasource.toggleFavorite(myUid, profile.uid);
    } catch (_) {
      if (mounted) {
        setState(() => _favorites?.add(profile));
      }
    }
  }

  Future<void> _startConversation(UserProfile profile) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final ids = [myUid, profile.uid]..sort();
    final conversationId = ids.join('_');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: ConversationModel(
            conversationId: conversationId,
            name1: profile.herName,
            name2: profile.hisName,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            gradientIndex: conversationId.hashCode.abs(),
            photoUrl: profile.photos.isNotEmpty ? profile.photos.first : null,
            pendingPartnerUid: profile.uid,
          ),
          otherProfile: profile,
        ),
      ),
    );
  }

  void _openProfile(UserProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartnerProfileScreen(profile: profile),
      ),
    );
  }

  int _ageFromBirth(String birth) {
    if (birth.isEmpty) return 0;
    try {
      final parts = birth.split('/');
      if (parts.length == 3) {
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
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.splashGradientEnd,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.favoriteCouples,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(l10n),
    );
  }

  List<UserProfile> get _filteredFavorites {
    final all = _favorites ?? [];
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((p) {
      return p.herName.toLowerCase().contains(q) ||
          p.hisName.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildSearch(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchCouples,
          hintStyle: const TextStyle(color: Color(0xFFA4A4AA), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA4A4AA)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFFA4A4AA), size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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
              l10n.errorLoadFavorites,
              style: const TextStyle(color: Colors.black45, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadFavorites,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final favorites = _favorites ?? [];

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noFavoriteCouples,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredFavorites;

    return Column(
      children: [
        _buildSearch(l10n),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    '🔍',
                    style: const TextStyle(fontSize: 48),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: const Color(0xFFB31637),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final profile = filtered[i];
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 520,
                              child: CoupleCard(
                                profile: coupleProfile,
                                isFavorite: true,
                                onToggleFavorite: () =>
                                    _confirmRemoveFavorite(profile),
                                onStartConversation: () =>
                                    _startConversation(profile),
                                onTap: () => _openProfile(profile),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _startConversation(profile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB31637),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.25),
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
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
