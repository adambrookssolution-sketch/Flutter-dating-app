import 'package:app/presentation/pages/community/community_screen.dart';
import 'package:app/presentation/pages/couples/couples_screen.dart';
import 'package:app/presentation/pages/inbox/inbox_screen.dart';
import 'package:app/presentation/pages/profile/profile_screen.dart';
import 'package:app/presentation/layouts/system_layout.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  AppRoutes._();

  static const String couples   = '/couples';
  static const String community = '/community';
  static const String inbox     = '/inbox';
  static const String profile   = '/profile';

  static final Map<String, WidgetBuilder> routes = {
    couples:   (_) => const CouplesScreen(),
    community: (_) => const CommunityScreen(),
    inbox:     (_) => const InboxScreen(),
    profile:   (_) => const ProfileScreen(),
  };

  static String fromTab(NavTab tab) => switch (tab) {
    NavTab.couples   => couples,
    NavTab.community => community,
    NavTab.inbox     => inbox,
    NavTab.profile   => profile,
  };
}
