import 'dart:async';

import 'package:flutter/material.dart';

const Color _accentColor = Color(0x70E24696); // #E24696 at 44% opacity
const Color _cardBorderColor = Color(0xFFB31637);

class CoupleProfile {
  final String uid;
  final String name1;
  final int age1;
  final String name2;
  final int age2;
  final String location;
  final String date;
  final String description;
  final List<String> tags;
  final List<String> photos;

  int get photoCount => photos.isEmpty ? 1 : photos.length;

  const CoupleProfile({
    required this.uid,
    required this.name1,
    required this.age1,
    required this.name2,
    required this.age2,
    required this.location,
    this.date = '',
    required this.description,
    required this.tags,
    this.photos = const [],
  });
}

class CoupleCard extends StatefulWidget {
  final CoupleProfile profile;
  final VoidCallback onStartConversation;

  const CoupleCard({
    super.key,
    required this.profile,
    required this.onStartConversation,
  });

  @override
  State<CoupleCard> createState() => _CoupleCardState();
}

class _CoupleCardState extends State<CoupleCard> {
  // Session-level flag: hint shown once across all card instances
  static bool _photoHintShown = false;

  int _currentPhoto = 0;
  bool _showPhotoHint = false;
  Timer? _hintTimer;
  bool _isFavorite = false;

  static const List<List<Color>> _photoGradients = [
    [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
    [Color(0xFF4ECAFF), Color(0xFF3B82F6)],
    [Color(0xFFFF8A65), Color(0xFFE91E63)],
    [Color(0xFF66BB6A), Color(0xFF26A69A)],
    [Color(0xFFFFB74D), Color(0xFFE64A19)],
  ];

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _navigatePhoto(bool next) {
    final newIndex = next
        ? (_currentPhoto + 1) % widget.profile.photoCount
        : (_currentPhoto - 1 + widget.profile.photoCount) %
            widget.profile.photoCount;
    setState(() => _currentPhoto = newIndex);

    if (!_photoHintShown) {
      _photoHintShown = true;
      setState(() => _showPhotoHint = true);
      _hintTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showPhotoHint = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _cardBorderColor, width: 5),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapUp: (d) {
              if (d.localPosition.dx < constraints.maxWidth / 2) {
                _navigatePhoto(false);
              } else {
                _navigatePhoto(true);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildPhotoIndicators(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildFavoriteButton(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomInfo(context),
                ),
                if (_showPhotoHint) _buildPhotoHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final photos = widget.profile.photos;
    if (photos.isNotEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Image.network(
          photos[_currentPhoto % photos.length],
          key: ValueKey(_currentPhoto),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const ColoredBox(
              color: Color(0xFFEEEEEE),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB31637),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFEEEEEE),
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.black26, size: 48),
            ),
          ),
        ),
      );
    }
    final colors = _photoGradients[_currentPhoto % _photoGradients.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Container(
        key: ValueKey(_currentPhoto),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.favorite, size: 80, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    return Row(
      children: List.generate(widget.profile.photoCount, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            margin: EdgeInsets.only(
              right: i < widget.profile.photoCount - 1 ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: i == _currentPhoto
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () => setState(() => _isFavorite = !_isFavorite),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isFavorite
              ? Colors.red
              : Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite_border,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.2, 1.0],
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.88),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.profile.name1}(${widget.profile.age1})'
            ' & ${widget.profile.name2}(${widget.profile.age2})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 2),
              Text(
                widget.profile.location,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          if (widget.profile.date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.profile.date,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            widget.profile.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _buildTags(),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 66),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        clipBehavior: Clip.hardEdge,
        children: widget.profile.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoHint() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chevron_left, color: Colors.white, size: 36),
                SizedBox(height: 6),
                Text(
                  'Prev photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chevron_right, color: Colors.white, size: 36),
                SizedBox(height: 6),
                Text(
                  'Next photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
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

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 8.0;
    const gap = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dash),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
