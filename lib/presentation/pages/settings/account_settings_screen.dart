import 'package:flutter/material.dart';

import 'package:app/presentation/pages/settings/delete_account_screen.dart';

/// Settings hub. Currently contains the two privacy-critical entries
/// (Account Deletion, future password change). Other items will land here
/// over Weeks 2-4: 2FA toggle, blocked list shortcut, etc.
///
/// Apple App Store explicitly requires Account Deletion to be reachable in
/// no more than 3 taps from the main navigation. The path here is:
/// Profile tab → Account Settings → Delete Account → confirmation.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            subtitle: const Text('Coming soon'),
            enabled: false,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Change email'),
            subtitle: const Text('Coming soon'),
            enabled: false,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DeleteAccountScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
