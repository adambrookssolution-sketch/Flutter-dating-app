import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/datasource/subscription_datasource.dart';
import 'package:app/data/models/subscription.dart';

/// Live subscription state for the signed-in couple.
///
/// Resolves to [SubscriptionState.free] when nobody is signed in or
/// while the Firestore doc hasn't been seeded yet. Widgets can read
/// this with `ref.watch(currentSubscriptionProvider)` to gate features.
final currentSubscriptionProvider = StreamProvider<SubscriptionState>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value(SubscriptionState.free());
  }
  return SubscriptionDatasource.watch(uid);
});

/// Convenience: boolean "does the caller currently have paid benefits?"
/// Use when you only need a yes/no (e.g. unlocking an advanced filter
/// section) and don't care about the specific tier.
final hasPaidBenefitsProvider = Provider<bool>((ref) {
  final async = ref.watch(currentSubscriptionProvider);
  return async.maybeWhen(
    data: (s) => s.hasActiveBenefits,
    orElse: () => false,
  );
});
