import 'package:flutter/material.dart';

/// In-app notifications inbox.
///
/// Surfaces events the user should react to: a verification decision,
/// new Travel Match, a chat reply, a report outcome, etc. The list items
/// themselves come from a [Firestore] collection the backend writes to
/// whenever the corresponding Cloud Function fires — wiring up the
/// subscription is part of the integration pass.
///
/// Accessed from the bell icon added to the Profile header on 2026-04-21.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFFB01030)),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 72,
                color: Color(0xFFB01030),
              ),
              SizedBox(height: 16),
              Text(
                'You have no notifications yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
