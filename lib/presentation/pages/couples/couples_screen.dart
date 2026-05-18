import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:app/presentation/pages/community/community_option.dart';
import 'package:app/presentation/pages/couples/couples_option.dart';
import 'package:app/presentation/pages/filters/filters_screen.dart';
import 'package:app/presentation/widgets/pineapple_filter_button.dart';
import 'package:app/presentation/widgets/secure_view.dart';
import 'package:app/providers/filters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CouplesScreen extends ConsumerStatefulWidget {
  const CouplesScreen({super.key});

  @override
  ConsumerState<CouplesScreen> createState() => _CouplesScreenState();
}

class _CouplesScreenState extends ConsumerState<CouplesScreen> {
  bool _isCouplesActive = true;

  Future<void> _openFiltersSheet() async {
    // Client spec (2026-04-21 mock): filters open as a bottom sheet that
    // covers the lower two thirds of the feed, not as a full page. That
    // keeps the couple card and the pineapple badge in view while the
    // user tweaks filters.
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollController) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: FiltersScreen(scrollController: scrollController),
        ),
      ),
    );
  }

  /// Count for the pineapple badge.
  int _countActive(FiltersState f) =>
      (f.centerLat != null ? 1 : 0) +
      (f.minAge != null || f.maxAge != null ? 1 : 0) +
      f.interests.length +
      (f.openToUnicorn == true ? 1 : 0) +
      (f.openToBull == true ? 1 : 0) +
      (f.travelDestinationId != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(filtersProvider);
    final activeCount = _countActive(filters);

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
                fontWeight:
                    _isCouplesActive ? FontWeight.bold : FontWeight.normal,
                color: _isCouplesActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
          // Client feedback 2026-05-18: the two tab labels were so
          // close together they read as one word. Widened the gutter
          // to 16 px so they're visually distinct.
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _isCouplesActive = false),
            child: Text(
              l10n.navCommunity,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    !_isCouplesActive ? FontWeight.bold : FontWeight.normal,
                color: !_isCouplesActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      // Per the 2026-04-20 mock the pineapple badge lives in the top-right
      // of the scaffold app bar itself (on the white header), not layered
      // on top of the feed. `appBarActions` routes it through the
      // SystemLayout's AppBar.actions slot so it stays sticky regardless
      // of list scroll position.
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
          child: PineappleFilterButton(
            activeCount: activeCount,
            onTap: _openFiltersSheet,
            size: 40,
          ),
        ),
      ],
      activeTab: NavTab.couples,
      // Wrap the body in SecureView so screenshots/recordings of the
      // discovery feed and community feed are blocked — client 2026-05-18
      // had flagged that user photos could be captured. The toggle is
      // reference-counted, so nested SecureViews (e.g. chat opened from
      // here) don't drop the flag prematurely.
      child: SecureView(
        child: _isCouplesActive
            ? const CouplesOption()
            : const CommunityOption(),
      ),
    );
  }
}
