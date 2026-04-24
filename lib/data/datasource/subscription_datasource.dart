import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:app/data/models/subscription.dart';

/// Reads the subscription state and calls the two Cloud Functions that
/// mutate it indirectly (everything actually mutates via Stripe webhooks).
///
/// The Flutter layer never writes to `subscriptions/*` directly —
/// Firestore security rules reject client writes. Callers should treat
/// this class as read-only for Firestore + RPC for the checkout /
/// cancel actions.
class SubscriptionDatasource {
  SubscriptionDatasource._();

  static final FirebaseFirestore _fs = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Live subscription state for a couple. Emits [SubscriptionState.free]
  /// until the Firestore document exists (the seed Cloud Function runs
  /// on couple creation so the gap is normally <1 s).
  static Stream<SubscriptionState> watch(String coupleId) {
    return _fs
        .collection('subscriptions')
        .doc(coupleId)
        .snapshots()
        .map((doc) =>
            doc.exists ? SubscriptionState.fromDoc(doc) : SubscriptionState.free())
        .handleError((_) => SubscriptionState.free());
  }

  /// One-shot read, for places that don't need a stream (e.g. a gate
  /// check before opening the paywall).
  static Future<SubscriptionState> get(String coupleId) async {
    try {
      final snap =
          await _fs.collection('subscriptions').doc(coupleId).get();
      return snap.exists
          ? SubscriptionState.fromDoc(snap)
          : SubscriptionState.free();
    } catch (_) {
      return SubscriptionState.free();
    }
  }

  /// Opens a Stripe Checkout session and returns the URL to hand off to
  /// `url_launcher`. The client never sees the Stripe secret — the
  /// Cloud Function builds the session server-side and returns the
  /// public session URL.
  ///
  /// [lookupKey] must be one of the constants in [PriceLookupKeys].
  /// [successUrl] / [cancelUrl] are where Stripe sends the user after
  /// the checkout flow completes or is abandoned.
  static Future<String> createCheckoutUrl({
    required String lookupKey,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call<Map<String, dynamic>>({
      'lookupKey': lookupKey,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    final url = result.data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Checkout session missing URL');
    }
    return url;
  }

  /// Marks the subscription to cancel at the end of the current period.
  /// Benefits keep flowing until [SubscriptionState.currentPeriodEnd].
  static Future<void> cancel() async {
    await _functions.httpsCallable('cancelSubscription').call();
  }
}
