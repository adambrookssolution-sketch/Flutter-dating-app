package com.affinitysocialclub.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * AFFINITY — Android host activity.
 *
 * Exposes a single MethodChannel ("affinity/secure_view") that Flutter can
 * use to add or clear FLAG_SECURE on the activity window.
 *
 * FLAG_SECURE prevents:
 *   - Screenshots (the system screenshot just shows a blank frame)
 *   - Screen recordings (the captured video stream is blanked)
 *   - The window appearing in the Recents thumbnail
 *
 * It applies window-wide, so we toggle it ON when entering a sensitive
 * screen and OFF when leaving. Caller responsibility (Flutter side) — see
 * [SecureView] widget.
 *
 * Package rename to `com.affinitysocialclub.app` happens in Week 5 store
 * prep along with branding; for now we keep the legacy package so existing
 * google-services.json / signing keys keep working in dev.
 */
class MainActivity : FlutterActivity() {

  private val secureChannelName = "affinity/secure_view"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      secureChannelName,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "enable" -> {
          runOnUiThread {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(true)
        }
        "disable" -> {
          runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Default OFF — sensitive screens opt in via [SecureView].
    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
  }
}
