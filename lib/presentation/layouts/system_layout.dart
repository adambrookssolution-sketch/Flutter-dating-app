import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/constants/app_dimensions.dart';
import 'package:app/presentation/router/app_routes.dart';
import 'package:flutter/material.dart';

enum NavTab { couples, community, inbox, profile }

class SystemLayout extends StatelessWidget {
  final List<Widget> appBarActions;
  final Widget? appBarTitle;
  final Widget child;
  final NavTab activeTab;

  const SystemLayout({
    super.key,
    this.appBarActions = const [],
    this.appBarTitle,
    required this.child,
    required this.activeTab,
  });

  void _navigate(BuildContext context, NavTab tab) {
    if (tab == activeTab) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.fromTab(tab),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
      (NavTab.couples, l10n.navCouples),
      // (NavTab.community, l10n.navCommunity),
      (NavTab.inbox, l10n.navInbox),
      (NavTab.profile, l10n.navProfile),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: appBarTitle,
        titleSpacing: AppDimensions.systemMargin,
        actions: appBarActions,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.systemMargin,
        ),
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: tabs.map((entry) {
              final (tab, label) = entry;
              final isActive = tab == activeTab;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigate(context, tab),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
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
      ),
    );
  }
}
