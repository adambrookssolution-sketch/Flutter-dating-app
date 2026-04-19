import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:app/presentation/pages/community/community_option.dart';
import 'package:app/presentation/pages/couples/couples_option.dart';
import 'package:flutter/material.dart';

class CouplesScreen extends StatefulWidget {
  const CouplesScreen({super.key});

  @override
  State<CouplesScreen> createState() => _CouplesScreenState();
}

class _CouplesScreenState extends State<CouplesScreen> {
  bool _isCouplesActive = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SystemLayout(
      appBarTitle: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isCouplesActive = true),
            child: Text(
              l10n.navCouples,
              style: TextStyle(
                fontSize: 18,
                fontWeight: _isCouplesActive ? FontWeight.bold : FontWeight.normal,
                color: _isCouplesActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _isCouplesActive = false),
            child: Text(
              l10n.navCommunity,
              style: TextStyle(
                fontSize: 18,
                fontWeight: !_isCouplesActive ? FontWeight.bold : FontWeight.normal,
                color: !_isCouplesActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      activeTab: NavTab.couples,
      child: _isCouplesActive ? const CouplesOption() : const CommunityOption(),
    );
  }
}
