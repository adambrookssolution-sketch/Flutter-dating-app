import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/admin/admin_app.dart';
import 'package:app/admin/pages/moderation_review_screen.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/couple_status.dart';

/// Queue view — couples waiting for verification review, oldest first.
///
/// Queries: `couples where status == pending_review order by verification.sent_at`.
/// Composite index already declared in `firestore.indexes.json`.
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  bool? _isModerator;
  String _filter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkClaim();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isModerator = false);
      return;
    }
    // Force refresh so a newly-minted claim shows up without re-login.
    final token = await user.getIdTokenResult(true);
    if (!mounted) return;
    setState(() => _isModerator = token.claims?['moderator'] == true);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isModerator == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_isModerator == false) {
      return _NoAccessView(onSignOut: _signOut);
    }

    final user = FirebaseAuth.instance.currentUser;
    final initial = (user?.email ?? '?').substring(0, 1).toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              email: user?.email ?? '',
              initial: initial,
              onSignOut: _signOut,
            ),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _filter = v.trim().toLowerCase()),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // No orderBy at the server: Firestore drops every doc
                // that doesn't have the indexed field, so couples whose
                // `verification.sent_at` was never written (e.g. a
                // pending-review doc that the user never advanced past
                // the video step) used to be invisible to the admin
                // panel — exactly what the client hit on 2026-05-18.
                // Sort in memory below; the queue is bounded to
                // `pending_review` so the result set stays small.
                stream: FirebaseFirestore.instance
                    .collection('couples')
                    .where('status',
                        isEqualTo: CoupleStatus.pendingReview.value)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _ErrorState(error: snap.error.toString());
                  }
                  if (!snap.hasData) {
                    return const _LoadingState();
                  }
                  // Only show couples that completed BOTH the photo upload
                  // and the verification-video upload. The profile-setup
                  // screen currently flips status to pending_review the
                  // moment a couple finishes the profile form, but a
                  // couple is only truly reviewable once the video is in
                  // Storage AND at least one photo exists. Anything else
                  // is an incomplete registration that the user can come
                  // back to from the app — it doesn't belong in the
                  // moderator queue.
                  final allRaw =
                      snap.data!.docs.map(Couple.fromDoc).toList();
                  // Sort newest-first by verification.sent_at when
                  // present, falling back to created_at, so partially
                  // submitted couples still surface (they used to
                  // disappear when the server-side orderBy excluded
                  // them).
                  allRaw.sort((a, b) {
                    final av = a.verification?.sentAt ?? a.createdAt;
                    final bv = b.verification?.sentAt ?? b.createdAt;
                    if (av == null && bv == null) return 0;
                    if (av == null) return 1;
                    if (bv == null) return -1;
                    return bv.compareTo(av);
                  });
                  // Show every pending-review couple — including the
                  // ones whose video upload silently failed (Storage
                  // permission, network, etc.). The previous
                  // `hasVideo && hasPhotos` filter was hiding those
                  // and leaving the user stuck on "Verification in
                  // review" forever, because the moderator never saw
                  // the row to act on (client 2026-05-18: test2 case).
                  // Incomplete entries surface in the queue and the
                  // moderator can still reject or approve manually.
                  final all = allRaw;
                  final filtered = _filter.isEmpty
                      ? all
                      : all.where((c) {
                          final hay =
                              '${c.partnerA.name} ${c.partnerB.name} ${c.city} ${c.country}'
                                  .toLowerCase();
                          return hay.contains(_filter);
                        }).toList();
                  if (filtered.isEmpty) {
                    return _EmptyState(searching: _filter.isNotEmpty);
                  }
                  return _QueueList(items: filtered, totalCount: all.length);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.email,
    required this.initial,
    required this.onSignOut,
  });

  final String email;
  final String initial;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminApp.burgundy, AdminApp.purple],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AdminApp.burgundy.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.shield_moon_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cola de verificación · v2',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AdminApp.textPrimary,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: AdminApp.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          _UserChip(initial: initial, onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.initial, required this.onSignOut});

  final String initial;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AdminApp.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminApp.line),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: const [
              Icon(Icons.logout_rounded, size: 18, color: AdminApp.textMuted),
              SizedBox(width: 10),
              Text('Cerrar sesión',
                  style: TextStyle(color: AdminApp.textPrimary)),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'signout') onSignOut();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AdminApp.bgRaised,
          border: Border.all(color: AdminApp.line),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: AdminApp.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Search ──────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AdminApp.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre, ciudad o país…',
          prefixIcon: Icon(Icons.search_rounded, color: AdminApp.textMuted),
        ),
      ),
    );
  }
}

// ── Queue list ──────────────────────────────────────────────────────────────

class _QueueList extends StatelessWidget {
  const _QueueList({required this.items, required this.totalCount});

  final List<Couple> items;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _CountBadge(
            shown: items.length,
            total: totalCount,
          );
        }
        final c = items[i - 1];
        return _QueueRow(couple: c);
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = shown == total
        ? '$total pendientes'
        : '$shown de $total pendientes';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AdminApp.gold,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AdminApp.gold.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AdminApp.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.couple});

  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final c = couple;
    final initials = _initials(c.partnerA.name, c.partnerB.name);
    final attempts = c.verification?.attempts ?? 1;
    final attemptColor = attempts >= 2 ? AdminApp.gold : AdminApp.burgundyLight;

    return Material(
      color: AdminApp.bgCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModerationReviewScreen(couple: c),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AdminApp.line),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              // Couple avatar — gradient initials. The first photo would go
              // here once Storage is on Blaze; for now this is a clean,
              // dignified placeholder that matches the brand.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AdminApp.burgundy, AdminApp.purple],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.partnerA.name} & ${c.partnerB.name}',
                      style: const TextStyle(
                        color: AdminApp.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: AdminApp.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _location(c),
                            style: const TextStyle(
                              color: AdminApp.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AttemptChip(attempts: attempts, color: attemptColor),
                  const SizedBox(height: 6),
                  Text(
                    _relative(c.verification?.sentAt),
                    style: const TextStyle(
                      color: AdminApp.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AdminApp.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String a, String b) {
    String first(String s) =>
        s.trim().isEmpty ? '?' : s.trim().substring(0, 1).toUpperCase();
    return '${first(a)}${first(b)}';
  }

  static String _location(Couple c) {
    if (c.city.trim().isNotEmpty && c.country.trim().isNotEmpty) {
      return '${c.city}, ${c.country}';
    }
    if (c.city.trim().isNotEmpty) return c.city;
    if (c.country.trim().isNotEmpty) return c.country;
    return 'Ubicación no informada';
  }

  static String _relative(DateTime? d) {
    if (d == null) return 'recién';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'recién';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 48) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}

class _AttemptChip extends StatelessWidget {
  const _AttemptChip({required this.attempts, required this.color});

  final int attempts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Intento $attempts/2',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── States ──────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminApp.bgRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminApp.line),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 32,
                color: AdminApp.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              searching
                  ? 'Sin resultados'
                  : 'Cola vacía',
              style: const TextStyle(
                color: AdminApp.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Ningún perfil coincide con tu búsqueda.'
                  : 'No hay verificaciones pendientes ahora mismo. Volverán a aparecer aquí en cuanto lleguen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminApp.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AdminApp.danger, size: 36),
            const SizedBox(height: 14),
            const Text(
              'No se pudo cargar la cola',
              style: TextStyle(
                color: AdminApp.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminApp.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  final Future<void> Function() onSignOut;
  const _NoAccessView({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AdminApp.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AdminApp.danger, size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sin acceso',
                style: TextStyle(
                  color: AdminApp.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esta cuenta no tiene permiso de moderadora.\nContacta al administrador para solicitar acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AdminApp.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                height: 48,
                child: OutlinedButton(
                  onPressed: onSignOut,
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
