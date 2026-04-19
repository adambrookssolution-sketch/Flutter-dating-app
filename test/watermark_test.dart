import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:app/core/security/watermark.dart';

/// Round-trip tests for the LSB watermarker.
///
/// We generate a solid-colour bitmap of known size, encode a couple ID into
/// it, then run the decoder and expect the original ID back. Solid colours
/// are the worst case — every pixel in a block starts with the same LSB,
/// so errors show up immediately.
void main() {
  group('Watermarker', () {
    Uint8List makeBitmap(int w, int h, int gray) {
      final image = img.Image(width: w, height: h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          image.setPixelRgba(x, y, gray, gray, gray, 255);
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    }

    test('encode -> decode round-trips a couple ID', () {
      final src = makeBitmap(320, 320, 128);
      final encoded = Watermarker.encode(src, 'couple_abcdef12');
      expect(encoded.length, greaterThan(0));
      final decoded = WatermarkDecoder.decode(encoded);
      expect(decoded, equals('couple_abcdef12'));
    });

    test('decode on unwatermarked image returns null', () {
      final plain = makeBitmap(320, 320, 200);
      final decoded = WatermarkDecoder.decode(plain);
      expect(decoded, isNull);
    });

    test('encode returns input unchanged when coupleId is too long', () {
      final src = makeBitmap(80, 80, 100);
      final bogus = 'x' * 100; // well above the 64-byte sanity cap
      final encoded = Watermarker.encode(src, bogus);
      // Identical bytes means the encoder bailed; assert length equality as
      // a proxy (PNG re-encoding would change bytes).
      expect(encoded.length, equals(src.length));
    });

    test('encode survives an image too small for the payload', () {
      // 24x24 gives only 9 blocks — way under magic + length + any ID.
      final tiny = makeBitmap(24, 24, 128);
      final encoded = Watermarker.encode(tiny, 'couple_xy');
      // Encoder bails gracefully and returns the original bytes.
      expect(encoded.length, equals(tiny.length));
    });
  });
}
