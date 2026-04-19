import 'package:flutter/material.dart';

import 'package:app/data/datasource/recovery_datasource.dart';

/// Pops a one-time dialog after sign-in if there are pending (un-acknowledged)
/// password recovery attempts. The user sees who tried to reset their
/// password (date + device), so a stranger's attempt is immediately visible.
///
/// DECISIONS_LOG Point 2: "Register all recovery attempts with IP, device,
/// date" + "In-app notification showing recovery attempts".
///
/// Call [maybeShow] from any post-sign-in landing screen (couples, profile,
/// pending-review). It returns silently when there's nothing to show.
class RecoveryAttemptsDialog {
  RecoveryAttemptsDialog._();

  /// Shows the dialog if there are pending attempts. Idempotent — calling
  /// this multiple times in one session only shows the dialog once because
  /// we mark attempts as acknowledged the first time.
  static Future<void> maybeShow(BuildContext context) async {
    final attempts = await RecoveryDatasource.streamMyRecentAttempts()
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => const []);
    final pending = attempts.where((a) => !a.completed).toList();
    if (pending.isEmpty) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Recovery activity on your account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A password recovery was requested:',
              style: TextStyle(color: Color(0xFF555555)),
            ),
            const SizedBox(height: 12),
            for (final a in pending.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${_formatDate(a.date)} — ${a.device ?? 'unknown device'}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              "If this wasn't you, change your password now and contact support.",
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return 'unknown date';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
