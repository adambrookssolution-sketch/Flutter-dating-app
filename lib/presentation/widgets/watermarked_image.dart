import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app/core/security/watermark.dart';

/// Memory-only image renderer that embeds the current viewer's couple ID
/// as a Watermark (LSB) before showing it.
///
/// Why we don't use `Image.network` directly:
///   - We need the raw bytes to run the watermark encoder before display.
///   - We must NOT cache the resulting bytes to disk (DECISIONS_LOG Point 7
///     "no local cache for sensitive images"). The Flutter framework's
///     in-memory image cache is fine because it dies with the app process,
///     but disk caching frameworks (cached_network_image) are not.
///
/// Behaviour:
///   - Loading state: a tiny CircularProgressIndicator inside a coloured
///     placeholder box matching the requested aspect ratio.
///   - Error state: a generic broken-image icon.
///   - Per-image cache key includes viewer ID so two viewers see different
///     watermarks for the same source.
///
/// Watermark encoding is async + done off the UI thread via [compute] so
/// scrolling stays at 60fps even on lower-end devices.
class WatermarkedImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const WatermarkedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<WatermarkedImage> createState() => _WatermarkedImageState();
}

class _WatermarkedImageState extends State<WatermarkedImage> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant WatermarkedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = _load();
    }
  }

  Future<Uint8List> _load() async {
    final resp = await http.get(Uri.parse(widget.url));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final viewer = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    return compute(_encodeIsolate, _EncodeArgs(resp.bodyBytes, viewer));
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

class _EncodeArgs {
  final Uint8List bytes;
  final String viewer;
  const _EncodeArgs(this.bytes, this.viewer);
}

Uint8List _encodeIsolate(_EncodeArgs args) {
  return Watermarker.encode(args.bytes, args.viewer);
}
