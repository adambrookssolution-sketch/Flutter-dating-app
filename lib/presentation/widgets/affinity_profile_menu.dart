import 'package:flutter/material.dart';

import 'package:app/core/feature_flags.dart';
import 'package:app/presentation/pages/security/security_screen.dart';
import 'package:app/presentation/pages/settings/account_settings_screen.dart';
import 'package:app/presentation/pages/subscription/my_subscription_screen.dart';
import 'package:app/presentation/pages/trips/manage_trips_screen.dart';

/// Single drop-in widget that adds Gabriel's four Profile menu entries
/// to the agency's Profile screen.
///
/// Designed for the merge: the agency dev pastes ONE import + ONE line
/// inside their existing Profile `Column` / `ListView` and gets all
/// four items wired to their navigation, all four hidden behind a
/// feature flag for emergency rollback, and consistent visual styling.
///
/// Integration on the agency's profile screen:
///
/// ```dart
/// import 'package:app/presentation/widgets/affinity_profile_menu.dart';
///
/// // ... inside the existing menu Column / ListView ...
/// const AffinityProfileMenu(),
/// ```
///
/// That's it. No state, no controllers, no extra props. If the menu
/// needs to be hidden in an emergency, flip
/// [FeatureFlags.gabrielProfileEntriesEnabled] to `false`.
///
/// Visual style matches the agency's existing Profile menu (white
/// surface, rounded leading icon, ListTile semantics) so the four new
/// items don't look like they came from a different app.
class AffinityProfileMenu extends StatelessWidget {
  const AffinityProfileMenu({
    super.key,
    this.iconColor = const Color(0xFFB01030),
    this.iconBackground = const Color(0xFFFCE7EC),
  });

  /// Foreground color of the menu icons. Defaults to Affinity burgundy.
  final Color iconColor;

  /// Background color of the rounded leading badge behind each icon.
  /// Defaults to a light burgundy tint.
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.gabrielProfileEntriesEnabled) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuTile(
          icon: Icons.flight_takeoff_rounded,
          label: 'Manage trips',
          iconColor: iconColor,
          iconBackground: iconBackground,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageTripsScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.shield_outlined,
          label: 'Security',
          iconColor: iconColor,
          iconBackground: iconBackground,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecurityScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          label: 'Account settings',
          iconColor: iconColor,
          iconBackground: iconBackground,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
          ),
        ),
        if (FeatureFlags.subscriptionStatusVisible ||
            FeatureFlags.subscriptionsEnabled)
          _MenuTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Tu plan',
            iconColor: iconColor,
            iconBackground: iconBackground,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MySubscriptionScreen()),
            ),
          ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFA4A4AA)),
    );
  }
}
