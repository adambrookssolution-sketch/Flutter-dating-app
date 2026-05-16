import 'dart:async';

import 'package:app/data/datasource/conversation_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/constants/app_dimensions.dart';
import 'package:app/presentation/router/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum NavTab { couples, community, inbox, profile }

class SystemLayout extends StatefulWidget {
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

  @override
  State<SystemLayout> createState() => _SystemLayoutState();
}

class _SystemLayoutState extends State<SystemLayout> {
  StreamSubscription<int>? _requestSub;
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _requestSub =
          ConversationDatasource.pendingRequestsStream(uid).listen((count) {
        if (mounted) setState(() => _pendingRequests = count);
      });
    }
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    super.dispose();
  }

  void _navigate(BuildContext context, NavTab tab) {
    if (tab == widget.activeTab) return;
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
        title: widget.appBarTitle,
        titleSpacing: AppDimensions.systemMargin,
        actions: widget.appBarActions,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.systemMargin,
        ),
        child: widget.child,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 56,
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: tabs.map((entry) {
              final (tab, label) = entry;
              final isActive = tab == widget.activeTab;
              final showBadge =
                  tab == NavTab.inbox && _pendingRequests > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigate(context, tab),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
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
                            if (showBadge)
                              Positioned(
                                top: -4,
                                right: -10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB31637),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 14),
                                  child: Text(
                                    _pendingRequests > 9
                                        ? '9+'
                                        : '$_pendingRequests',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
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
