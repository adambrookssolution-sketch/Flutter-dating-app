import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Loads a network image into memory and displays it — NEVER hits the disk
/// cache used by `cached_network_image` or Flutter's ImageProvider cache
/// manager.
///
/// Use for images sensitive to local persistence but not requiring the full
/// watermark overhead (e.g. message request preview, trip destination hero
/// image). For other couples' profile photos inside chat / profile view,
/// prefer [WatermarkedImage] instead — it also enforces no-disk-cache.
class NoCacheImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NoCacheImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<NoCacheImage> createState() => _NoCacheImageState();
}

class _NoCacheImageState extends State<NoCacheImage> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _fetch(widget.url);
  }

  @override
  void didUpdateWidget(covariant NoCacheImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _bytes = _fetch(widget.url);
  }

  static Future<Uint8List> _fetch(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasError) {
          return _placeholder(const Icon(Icons.broken_image,
              color: Color(0xFFA4A4AA)));
        }
        if (!snap.hasData) {
          return _placeholder(const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
        }
        return Image.memory(
          snap.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
        );
      },
    );
  }

  Widget _placeholder(Widget child) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: child,
      );
}
