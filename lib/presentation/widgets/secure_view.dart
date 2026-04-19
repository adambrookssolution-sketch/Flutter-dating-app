import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] so screenshots and screen recordings capture a black frame
/// over the protected area.
///
/// Implementation per platform (DECISIONS_LOG Point 7):
/// - **Android**: window-wide `FLAG_SECURE` toggled via the `affinity/secure_view`
///   MethodChannel (see [MainActivity.kt]). Toggled ON in `initState`, OFF
///   in `dispose`. Multiple SecureView instances reference-count via
///   [_AndroidFlagRefCount] so a parent doesn't accidentally drop the flag
///   while a nested SecureView still needs it.
/// - **iOS**: a hidden `UITextField(isSecureTextEntry: true)` PlatformView
///   sits behind the child. iOS marks that layer as system-protected, so
///   the captured frame is blank wherever it lies. See [SecureView.swift].
/// - **Other platforms / Flutter Web / desktop**: no-op; child renders normally.
///
/// Apply this around: chat conversations, image gallery, full-size couple
/// profiles, Travel Match results, Request preview screens. Do NOT apply to
/// the user's own profile editing flow — they may legitimately want a
/// screenshot of their own setup.
class SecureView extends StatefulWidget {
  final Widget child;

  const SecureView({super.key, required this.child});

  @override
  State<SecureView> createState() => _SecureViewState();
}

class _SecureViewState extends State<SecureView> {
  static const MethodChannel _channel =
      MethodChannel('affinity/secure_view');

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      _AndroidFlagRefCount.acquire(_channel);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isAndroid) {
      _AndroidFlagRefCount.release(_channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    if (Platform.isIOS) {
      // iOS: stack a 0-area PlatformView behind the child. iOS still marks
      // the area covered by the secure UITextField as protected.
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: UiKitView(
                viewType: 'affinity/secure_view',
                creationParams: const <String, dynamic>{},
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          ),
          widget.child,
        ],
      );
    }

    // Android already protects the whole window via FLAG_SECURE; render
    // the child normally.
    return widget.child;
  }
}

/// Tracks how many [SecureView] instances are mounted so the underlying
/// FLAG_SECURE is only cleared when the LAST one is disposed. Without this
/// a chat opened on top of a Travel Match screen would clear the flag for
/// the parent on its own dispose.
class _AndroidFlagRefCount {
  _AndroidFlagRefCount._();

  static int _count = 0;

  static Future<void> acquire(MethodChannel channel) async {
    _count++;
    if (_count == 1) {
      try {
        await channel.invokeMethod('enable');
      } catch (_) {
        // Channel may not exist on early app start or non-Android targets;
        // we already gated by Platform.isAndroid so failures here are
        // unexpected but non-fatal.
      }
    }
  }

  static Future<void> release(MethodChannel channel) async {
    if (_count == 0) return;
    _count--;
    if (_count == 0) {
      try {
        await channel.invokeMethod('disable');
      } catch (_) {}
    }
  }
}
