import 'package:flutter/material.dart';

/// Bottom-pinned action bar for the Couples / Community feed.
///
/// Matches the 2026-04-20 reference mock: a filled burgundy
/// "Start Conversation" CTA stacked above an outlined "Filters" button,
/// both pinned to the bottom so they stay visible while the user scrolls
/// through couple cards.
///
/// The parent screen is responsible for tracking *which* couple is
/// currently front-and-centre (e.g. via a `PageController` or an
/// `onVisibleCoupleChanged` callback on the list view) and passing that
/// info into [onStartConversation] — this widget is deliberately dumb so
/// it can drop into any feed layout without coupling to a particular
/// state management library.
///
/// ## Integration
///
/// Wrap the feed body in a [Column] (or a [Stack] with a [Positioned] at
/// the bottom) so the buttons stay fixed:
///
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       Expanded(child: CouplesListView(...)),
///       StickyFeedActions(
///         onStartConversation: () => _sendRequest(currentVisibleCouple),
///         onFilters: () => Navigator.push(... FiltersScreen ...),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// The [startConversationLabel] and [filtersLabel] default to English text
/// — pass localized strings when wiring into an `AppLocalizations` scope.
class StickyFeedActions extends StatelessWidget {
  const StickyFeedActions({
    super.key,
    required this.onStartConversation,
    required this.onFilters,
    this.startConversationLabel = 'Start Conversation',
    this.filtersLabel = 'Filters',
    this.enabled = true,
  });

  final VoidCallback onStartConversation;
  final VoidCallback onFilters;
  final String startConversationLabel;
  final String filtersLabel;

  /// When false both buttons render in their normal visual style but the
  /// tap callbacks are ignored — useful while a request is in flight.
  final bool enabled;

  static const Color _burgundy = Color(0xFFB31637);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: enabled ? onStartConversation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _burgundy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _burgundy.withValues(alpha: 0.4),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: enabled ? onFilters : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _burgundy,
                  side: const BorderSide(color: _burgundy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(filtersLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
