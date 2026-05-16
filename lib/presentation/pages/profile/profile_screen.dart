import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/notifications/notifications_screen.dart';
import 'package:app/presentation/pages/profile/favorite_couples_screen.dart';
import 'package:app/presentation/pages/profile_setup/profile_setup_screen.dart';
import 'package:app/presentation/pages/security/security_screen.dart';
import 'package:app/presentation/pages/settings/account_settings_screen.dart';
import 'package:app/presentation/pages/trips/manage_trips_screen.dart';
import 'package:app/presentation/router/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _headerTop = Color(0xFFB01030);
  static const Color _headerBottom = Color(0xFF4D0918);

  UserProfile? _profile;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _uid = uid;
    final profile = await ProfileDatasource.getProfile(uid);
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _goToEdit() async {
    if (_uid == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileSetupScreen(uid: _uid!, existingProfile: _profile),
      ),
    );
    _loadProfile();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOut),
        content: Text(l10n.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logOut,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthDatasource.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(screenH, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: _buildSettings(l10n),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(double screenH, AppLocalizations l10n) {
    final firstPhoto =
        (_profile != null && _profile!.photos.isNotEmpty)
            ? _profile!.photos.first
            : null;

    final displayName = _profile != null
        ? '${_profile!.hisName} & ${_profile!.herName}'
        : '···';

    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: screenH * 0.40,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_headerTop, _headerBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 3-column header: back button (only when the screen is
                // pushed, not when Profile is the root tab) / centred
                // "Profile" title / notification bell.
                // Matches the 2026-04-21 mock.
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Navigator.of(context).canPop()
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.navProfile,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _NotificationBellButton(onTap: _openNotifications),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar + edit pencil
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _goToEdit,
                              child: Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: firstPhoto != null
                                    ? ClipOval(
                                        child: Image.network(
                                          firstPhoto,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: Colors.white12,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image,
                                                  color: Colors.white54, size: 36),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B9D),
                                              Color(0xFFC44CFF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.favorite,
                                            color: Colors.white30,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            // Edit pencil icon
                            Positioned(
                              top: 0,
                              right: -4,
                              child: GestureDetector(
                                onTap: _goToEdit,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    // Purple pencil per the 2026-04-21 mock.
                                    child: Icon(
                                      Icons.edit,
                                      size: 15,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Settings list ────────────────────────────────────────────────────────────

  Widget _buildSettings(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSettings,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        _SettingItem(
          iconAsset: 'assets/images/icon_edit_profile.png',
          label: l10n.editProfile,
          onTap: _goToEdit,
        ),
        _SettingItem(
          iconAsset: 'assets/images/icon_manage_trip.png',
          label: l10n.manageTrips,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageTripsScreen()),
          ),
        ),
        _SettingItem(
          iconAsset: 'assets/images/icon_favorites_couples.png',
          label: l10n.viewFavoriteCouples,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FavoriteCouplesScreen(),
            ),
          ),
        ),
        _SettingItem(
          iconAsset: 'assets/images/icon_settings.png',
          label: l10n.accountSettings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccountSettingsScreen(),
            ),
          ),
        ),
        _SettingItem(
          iconAsset: 'assets/images/icon_security.png',
          label: l10n.security,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecurityScreen()),
          ),
        ),
        _SettingItem(
          iconAsset: 'assets/images/icon_help.png',
          label: l10n.help,
          onTap: () {},
        ),
        _SettingItem(
          iconData: Icons.logout_rounded,
          label: l10n.logOut,
          onTap: _signOut,
          destructive: true,
        ),
      ],
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────────

  Widget _buildBottomNav(AppLocalizations l10n) {
    final tabs = [
      (NavTab.couples, l10n.navCouples),
      (NavTab.inbox, l10n.navInbox),
      (NavTab.profile, l10n.navProfile),
    ];

    return SafeArea(
      child: Container(
        height: 56,
        color: Colors.white,
        child: Row(
          children: tabs.map((entry) {
            final (tab, label) = entry;
            final isActive = tab == NavTab.profile;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (tab != NavTab.profile) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.fromTab(tab),
                      (route) => false,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.splashGradientEnd
                              : const Color(0xFFA4A4AA),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.splashGradientEnd,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Wave clipper ──────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(
        size.width * 0.5, size.height + 20,
        size.width, size.height - 40,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

// ── Setting item ──────────────────────────────────────────────────────────────

class _SettingItem extends StatelessWidget {
  final String? iconAsset;
  final IconData? iconData;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingItem({
    this.iconAsset,
    this.iconData,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  static const Color _circleBg = Color(0x1C3C5AF6);
  static const Color _iconColor = Color(0xFF3C5AF6);
  static const Color _destructiveBg = Color(0x1CFF3B30);
  static const Color _destructiveColor = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? _destructiveColor : _iconColor;
    final circleBg = destructive ? _destructiveBg : _circleBg;
    final textColor = destructive ? _destructiveColor : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: iconAsset != null
                    ? Image.asset(iconAsset!, width: 22, height: 22)
                    : Icon(iconData, size: 22, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: destructive
                  ? _destructiveColor.withValues(alpha: 0.5)
                  : const Color(0xFFB9B9B9),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell icon that sits in the top-right of the Profile header.
///
/// Added per the client reference mock on 2026-04-21. It deliberately stays
/// a small pill-shaped button (white icon on translucent backdrop) so it
/// reads against the burgundy gradient header without stealing attention
/// from the couple avatar in the centre.
///
/// The optional [unreadCount] shows a red dot when the user has pending
/// notifications. Once the notifications Firestore collection is wired up,
/// subscribe the parent to it and pass the count here.
class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.onTap,
    // ignore: unused_element_parameter
    this.unreadCount = 0,
  });

  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            // Transparent — the mock has a bare bell outline on the
            // burgundy gradient, no background bubble.
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
