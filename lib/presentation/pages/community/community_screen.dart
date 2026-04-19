import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:app/presentation/pages/community/community_option.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SystemLayout(
      appBarTitle: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.navCouples, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            l10n.navCommunity,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      activeTab: NavTab.community,
      child: const CommunityOption(),
    );
  }
}
