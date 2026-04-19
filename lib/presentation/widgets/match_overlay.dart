import 'dart:math';

import 'package:flutter/material.dart';

class MatchOverlay extends StatefulWidget {
  final String name1;
  final int age1;
  final String name2;
  final int age2;
  final List<Color> matchedGradientColors;
  final VoidCallback onKeepSwiping;
  final VoidCallback onSendMessage;

  const MatchOverlay({
    super.key,
    required this.name1,
    required this.age1,
    required this.name2,
    required this.age2,
    required this.matchedGradientColors,
    required this.onKeepSwiping,
    required this.onSendMessage,
  });

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;

  // Staggered animations driven by _mainCtrl
  late final Animation<double> _bgOpacity;
  late final Animation<double> _photosOpacity;
  late final Animation<double> _leftSlide;
  late final Animation<double> _rightSlide;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _buttonsY;
  late final Animation<double> _buttonsOpacity;

  // Pulsing heart
  late final Animation<double> _heartPulse;

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    // Background: 0 → 20 %
    _bgOpacity = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
    );

    // Photos: 10 → 55 %
    _photosOpacity = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.10, 0.45, curve: Curves.easeOut),
    );
    _leftSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _rightSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Title: 35 → 68 %
    _titleOpacity = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.35, 0.55, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.35, 0.68, curve: Curves.elasticOut),
      ),
    );

    // Subtitle: 58 → 75 %
    _subtitleOpacity = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.58, 0.75, curve: Curves.easeOut),
    );

    // Buttons: 68 → 88 %
    _buttonsOpacity = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.68, 0.88, curve: Curves.easeOut),
    );
    _buttonsY = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.68, 0.88, curve: Curves.easeOut),
      ),
    );

    // Heart pulse
    _heartPulse = Tween<double>(begin: 0.88, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _mainCtrl.forward();
  }

  List<_Particle> _buildParticles() {
    final rng = Random(42);
    const colors = [
      Color(0xFFE24696),
      Color(0xFFB31637),
      Color(0xFFFF6B9D),
      Color(0xFFFFD700),
      Colors.white,
    ];
    return List.generate(20, (i) {
      return _Particle(
        xFraction: rng.nextDouble(),
        phase: rng.nextDouble(),
        speed: 0.55 + rng.nextDouble() * 0.45,
        size: 9.0 + rng.nextDouble() * 13.0,
        opacity: 0.45 + rng.nextDouble() * 0.55,
        wavePhase: rng.nextDouble() * 2 * pi,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _particleCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Background gradient
              Opacity(
                opacity: _bgOpacity.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A0012),
                        Color(0xFF2D0025),
                        Color(0xFF0D0018),
                      ],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),

              // Floating heart particles
              Opacity(
                opacity: _bgOpacity.value,
                child: CustomPaint(
                  size: screenSize,
                  painter: _ParticlePainter(
                    progress: _particleCtrl.value,
                    particles: _particles,
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Opacity(
                  opacity: _bgOpacity.value,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Profile circles + heart
                      _buildAvatarRow(screenSize),

                      const SizedBox(height: 36),

                      // "¡ES UN MATCH!"
                      _buildTitle(),

                      const SizedBox(height: 10),

                      // Subtitle
                      FadeTransition(
                        opacity: _subtitleOpacity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            '${widget.name1} & ${widget.name2} también'
                            ' les han dado like',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Action buttons
                      _buildButtons(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarRow(Size screenSize) {
    const double avatarSize = 112.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Your couple (slides from left)
        Transform.translate(
          offset: Offset(_leftSlide.value * screenSize.width * 0.55, 0),
          child: Opacity(
            opacity: _photosOpacity.value,
            child: _Avatar(
              size: avatarSize,
              gradient: const LinearGradient(
                colors: [Color(0xFF331837), Color(0xFFB31637)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              topLabel: 'Vosotros',
              bottomLabel: '',
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Pulsing heart connector
        ScaleTransition(
          scale: _heartPulse,
          child: Opacity(
            opacity: _titleOpacity.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFB31637),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB31637).withValues(alpha: 0.65),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 22),
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Matched couple (slides from right)
        Transform.translate(
          offset: Offset(_rightSlide.value * screenSize.width * 0.55, 0),
          child: Opacity(
            opacity: _photosOpacity.value,
            child: _Avatar(
              size: avatarSize,
              gradient: LinearGradient(
                colors: widget.matchedGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              topLabel: widget.name1,
              bottomLabel: '& ${widget.name2}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return ScaleTransition(
      scale: _titleScale,
      child: FadeTransition(
        opacity: _titleOpacity,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFFD700), Color(0xFFFF6B9D)],
          ).createShader(bounds),
          child: const Text(
            '¡ES UN MATCH!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Transform.translate(
      offset: Offset(0, _buttonsY.value),
      child: Opacity(
        opacity: _buttonsOpacity.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onSendMessage,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Enviar mensaje',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB31637),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onKeepSwiping,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Seguir explorando',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final double size;
  final LinearGradient gradient;
  final String topLabel;
  final String bottomLabel;

  const _Avatar({
    required this.size,
    required this.gradient,
    required this.topLabel,
    required this.bottomLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.favorite, color: Colors.white30, size: 44),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          topLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (bottomLabel.isNotEmpty)
          Text(
            bottomLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
      ],
    );
  }
}

// ── Particle system ───────────────────────────────────────────────────────────

class _Particle {
  final double xFraction;
  final double phase;
  final double speed;
  final double size;
  final double opacity;
  final double wavePhase;
  final Color color;

  const _Particle({
    required this.xFraction,
    required this.phase,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.wavePhase,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  const _ParticlePainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1.0 - t);
      final x = p.xFraction * size.width +
          sin(t * 4 * pi + p.wavePhase) * 16;

      final fadeIn = t < 0.12 ? t / 0.12 : 1.0;
      final fadeOut = t > 0.78 ? (1.0 - t) / 0.22 : 1.0;
      final alpha = (fadeIn * fadeOut * p.opacity).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawPath(_heartPath(Offset(x, y), p.size), paint);
    }
  }

  /// Standard heart path centered at [center] within a [size]×[size] bounding box.
  Path _heartPath(Offset center, double size) {
    final w = size;
    final h = size;
    final x = center.dx - w / 2;
    final y = center.dy - h / 2;

    return Path()
      ..moveTo(x + w * 0.5, y + h * 0.35)
      ..cubicTo(
          x + w * 0.5, y + h * 0.24, x + w * 0.35, y + h * 0.18, x + w * 0.25, y + h * 0.18)
      ..cubicTo(x, y + h * 0.18, x, y + h * 0.54, x, y + h * 0.54)
      ..cubicTo(x, y + h * 0.77, x + w * 0.21, y + h * 0.9, x + w * 0.5, y + h)
      ..cubicTo(x + w * 0.79, y + h * 0.9, x + w, y + h * 0.77, x + w, y + h * 0.54)
      ..cubicTo(x + w, y + h * 0.54, x + w, y + h * 0.18, x + w * 0.75, y + h * 0.18)
      ..cubicTo(
          x + w * 0.65, y + h * 0.18, x + w * 0.5, y + h * 0.24, x + w * 0.5, y + h * 0.35)
      ..close();
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
