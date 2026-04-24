import 'package:flutter/material.dart';

/// Bottom-pinned "Start Conversation" CTA for the Couples / Community feed.
///
/// Per client feedback on 2026-04-23 the secondary "Filters" button was
/// removed so the couple's photo regains visual prominence; the pineapple
/// in the top-right is now the sole entry point to the filters panel.
///
/// The parent screen tracks which couple is currently front-and-centre and
/// passes that info into [onStartConversation]. The widget is deliberately
/// stateless so it drops into any feed layout without coupling to a
/// particular state management library.
class StickyFeedActions extends StatelessWidget {
  const StickyFeedActions({
    super.key,
    required this.onStartConversation,
    this.startConversationLabel = 'Start Conversation',
    this.enabled = true,
  });

  final VoidCallback onStartConversation;
  final String startConversationLabel;

  /// When false the button renders in its normal visual style but the tap
  /// callback is ignored — useful while a request is in flight.
  final bool enabled;

  static const Color _burgundy = Color(0xFFB31637);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onStartConversation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _burgundy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _burgundy.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              elevation: 0,
            ),
            child: Text(startConversationLabel),
          ),
        ),
      ),
    );
  }
}
