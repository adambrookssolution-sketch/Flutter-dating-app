import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register the SecureView platform view factory under the same channel
    // name the Flutter widget references. See [SecureView] (Dart) +
    // [SecureViewFactory] (Swift).
    if let registrar = self.registrar(forPlugin: "SecureView") {
      registrar.register(
        SecureViewFactory(messenger: registrar.messenger()),
        withId: "affinity/secure_view"
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
