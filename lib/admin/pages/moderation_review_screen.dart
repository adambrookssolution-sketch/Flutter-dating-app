import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:app/admin/admin_app.dart';
import 'package:app/data/models/couple.dart';

/// Per-couple review card. Dark, modern aesthetic with graceful fallbacks
/// for missing video / missing photos so the moderator never sees a blank
/// region and always knows whether a piece is loading, missing, or broken.
class ModerationReviewScreen extends StatefulWidget {
  final Couple couple;

  const ModerationReviewScreen({super.key, required this.couple});

  @override
  State<ModerationReviewScreen> createState() =>
      _ModerationReviewScreenState();
}

class _ModerationReviewScreenState extends State<ModerationReviewScreen> {
  VideoPlayerController? _player;
  bool _videoInitializing = false;
  String? _videoError;
  bool _submitting = false;

  // Rejection reasons — closed list, agreed with the client on 2026-04-21.
  static const _reasons = {
    'fotos_no_coinciden': 'Las fotos no coinciden entre sí',
    'video_poco_claro': 'El video es poco claro',
    'perfil_sospechoso': 'Perfil sospechoso',
    'fotos_inapropiadas': 'Fotos con contenido inapropiado',
    'solo_una_persona': 'Solo aparece una persona en las fotos/video',
    'menor_de_edad': 'Se sospecha que una de las personas es menor de edad',
    'calidad_baja': 'Calidad del video demasiado baja',
    'otro': 'Otro (ver guía de moderación)',
  };

  String? get _videoUrl {
    final v = widget.couple.verification?.videoUrl;
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final url = _videoUrl;
    if (url == null) return;
    setState(() {
      _videoInitializing = true;
      _videoError = null;
    });
    final p = VideoPlayerController.networkUrl(Uri.parse(url));
    p.initialize().then((_) {
      if (!mounted) return;
      p.setLooping(true);
      setState(() {
        _videoInitializing = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _videoInitializing = false;
        _videoError = e.toString();
      });
    });
    _player = p;
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _moderate({
    required String decision,
    String? reason,
  }) async {
    setState(() => _submitting = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('moderateVerification');
      await callable.call<Map<String, dynamic>>({
        'coupleId': widget.couple.id,
        'decision': decision,
        if (reason != null) 'reason': reason,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.code}: ${e.message}')),
      );
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _confirmApprove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Aprobar pareja',
        body:
            '¿Confirmas que esta pareja cumple los criterios de verificación? Pasará al feed de inmediato.',
        confirmLabel: 'Aprobar',
        confirmColor: AdminApp.success,
        icon: Icons.check_circle_rounded,
      ),
    );
    if (ok == true) {
      await _moderate(decision: 'approve');
    }
  }

  Future<void> _openRejectSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(reasons: _reasons),
    );
    if (picked != null) {
      await _moderate(decision: 'reject', reason: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.couple;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AdminApp.bgDeep,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    '${c.partnerA.name} & ${c.partnerB.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 4, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _MetaCard(couple: c),
                      const SizedBox(height: 18),
                      _SectionLabel('Video de verificación'),
                      const SizedBox(height: 10),
                      _VideoSection(
                        url: _videoUrl,
                        player: _player,
                        initializing: _videoInitializing,
                        error: _videoError,
                        onRetry: _initVideo,
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel('Fotos'),
                      const SizedBox(height: 10),
                      _PhotosSection(photos: c.photos),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
            if (_submitting) const _SubmittingOverlay(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ActionBar(
                onApprove: _submitting ? null : _confirmApprove,
                onReject: _submitting ? null : _openRejectSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AdminApp.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}

// ── Meta card ───────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final c = couple;
    final attempts = c.verification?.attempts ?? 1;
    return Container(
      decoration: BoxDecoration(
        color: AdminApp.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminApp.line),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          Row(
            children: [
              _CoupleAvatar(a: c.partnerA.name, b: c.partnerB.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.partnerA.name} & ${c.partnerB.name}',
                      style: const TextStyle(
                        color: AdminApp.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _location(c),
                      style: const TextStyle(
                        color: AdminApp.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _AttemptPill(attempts: attempts),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AdminApp.line),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaCell(label: 'Edad', value: _ageText(c)),
              _Divider(),
              _MetaCell(
                label: 'Recibido',
                value: _relative(c.verification?.sentAt),
              ),
              _Divider(),
              _MetaCell(label: 'ID', value: c.id.substring(0, 6)),
            ],
          ),
        ],
      ),
    );
  }

  String _location(Couple c) {
    if (c.city.trim().isNotEmpty && c.country.trim().isNotEmpty) {
      return '${c.city}, ${c.country}';
    }
    if (c.city.trim().isNotEmpty) return c.city;
    if (c.country.trim().isNotEmpty) return c.country;
    return 'Ubicación no informada';
  }

  String _ageText(Couple c) {
    final min = c.ageRange.min;
    final max = c.ageRange.max;
    if (min == max) return '$min';
    return '$min – $max';
  }

  String _relative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'recién';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 48) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}

class _CoupleAvatar extends StatelessWidget {
  const _CoupleAvatar({required this.a, required this.b});
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) {
    String first(String s) =>
        s.trim().isEmpty ? '?' : s.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AdminApp.burgundy, AdminApp.purple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        '${first(a)}${first(b)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AttemptPill extends StatelessWidget {
  const _AttemptPill({required this.attempts});
  final int attempts;

  @override
  Widget build(BuildContext context) {
    final isHighRisk = attempts >= 2;
    final color = isHighRisk ? AdminApp.gold : AdminApp.burgundyLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Intento $attempts/2',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AdminApp.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AdminApp.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AdminApp.line,
    );
  }
}

// ── Video section ───────────────────────────────────────────────────────────

class _VideoSection extends StatefulWidget {
  const _VideoSection({
    required this.url,
    required this.player,
    required this.initializing,
    required this.error,
    required this.onRetry,
  });

  final String? url;
  final VideoPlayerController? player;
  final bool initializing;
  final String? error;
  final VoidCallback onRetry;

  @override
  State<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<_VideoSection> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final player = widget.player;

    if (url == null) {
      return const _MissingMediaCard(
        icon: Icons.videocam_off_outlined,
        title: 'Sin video disponible',
        body:
            'Esta pareja envió su perfil pero el archivo de video no está accesible. En el entorno actual de pruebas, Cloud Storage está limitado al plan gratuito.',
      );
    }
    if (widget.error != null) {
      return _MediaErrorCard(error: widget.error!, onRetry: widget.onRetry);
    }
    if (widget.initializing || player == null || !player.value.isInitialized) {
      return const _MediaSkeleton(
        aspectRatio: 9 / 16,
        labelTop: 'Cargando video…',
      );
    }
    return AspectRatio(
      aspectRatio: player.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: VideoPlayer(player),
            ),
            // Subtle gradient so the play button + bar always read on
            // any video content.
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                              alpha: _showControls ? 0.18 : 0.0),
                          Colors.transparent,
                          Colors.black.withValues(
                              alpha: _showControls ? 0.55 : 0.0),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showControls) ...[
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 30,
                    color: Colors.white,
                    icon: Icon(player.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    onPressed: () {
                      setState(() {
                        player.value.isPlaying
                            ? player.pause()
                            : player.play();
                      });
                    },
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: VideoProgressIndicator(
                  player,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white.withValues(alpha: 0.4),
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Photos section ──────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _MissingMediaCard(
        icon: Icons.photo_library_outlined,
        title: 'Sin fotos disponibles',
        body:
            'Esta pareja no tiene fotos de perfil cargadas en este entorno. La subida de imágenes a Cloud Storage se activa al pasar al Firebase de producción.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const cols = 3;
        final tile = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: photos
              .map(
                (url) => _PhotoTile(
                  url: url,
                  size: tile,
                  onTap: () => _openLightbox(context, url),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _openLightbox(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _PhotoLightbox(url: url),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.size,
    required this.onTap,
  });

  final String url;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminApp.bgRaised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                final value = progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!;
                return Container(
                  color: AdminApp.bgRaised,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: value,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AdminApp.bgRaised,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AdminApp.textMuted,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoLightbox extends StatelessWidget {
  const _PhotoLightbox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                url,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton + Error + Missing ──────────────────────────────────────────────

class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton({
    required this.aspectRatio,
    required this.labelTop,
  });
  final double aspectRatio;
  final String labelTop;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: AdminApp.bgRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminApp.line),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            Text(
              labelTop,
              style: const TextStyle(
                color: AdminApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaErrorCard extends StatelessWidget {
  const _MediaErrorCard({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AdminApp.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminApp.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AdminApp.danger, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'No se pudo cargar el video',
                  style: TextStyle(
                    color: AdminApp.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AdminApp.burgundyLight,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminApp.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingMediaCard extends StatelessWidget {
  const _MissingMediaCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AdminApp.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminApp.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AdminApp.bgRaised,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AdminApp.line),
            ),
            child: Icon(icon, color: AdminApp.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminApp.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AdminApp.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar ──────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onApprove, required this.onReject});
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminApp.bgDeep.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AdminApp.line),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded,
                      color: AdminApp.danger, size: 20),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(
                      color: AdminApp.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AdminApp.danger.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: onApprove == null
                            ? [
                                AdminApp.success.withValues(alpha: 0.4),
                                AdminApp.success.withValues(alpha: 0.4),
                              ]
                            : [
                                AdminApp.success,
                                const Color(0xFF2BA873),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Aprobar pareja',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reject sheet ────────────────────────────────────────────────────────────

class _RejectSheet extends StatelessWidget {
  const _RejectSheet({required this.reasons});
  final Map<String, String> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminApp.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminApp.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Motivo de rechazo',
                style: TextStyle(
                  color: AdminApp.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'La pareja recibirá este motivo en su pantalla de rechazo.',
                style: TextStyle(
                  color: AdminApp.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ...reasons.entries.map(
                (e) => _ReasonOption(
                  label: e.value,
                  onTap: () => Navigator.pop(context, e.key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AdminApp.bgRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminApp.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AdminApp.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AdminApp.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confirm dialog + submitting overlay ─────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminApp.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: confirmColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AdminApp.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminApp.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.5),
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}
