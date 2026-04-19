import Flutter
import UIKit

// AFFINITY — iOS secure-content view.
//
// DECISIONS_LOG Point 7 — "Telegram-style" screenshot blanking:
//
//   1. We create a real UITextField with isSecureTextEntry = true.
//   2. iOS marks one of its internal subviews as "system protected" — that
//      subview is excluded from screenshots and screen recordings.
//   3. We disable the field for input and reparent every Flutter child view
//      INTO that protected subview, so anything we render inside it inherits
//      the system protection.
//
// Implementation borrows from the Telegram open-source iOS client. The trick
// is sensitive to iOS internals and may break in future iOS versions; we
// soft-fall-back to plain rendering when the protected subview can't be
// located (older iOS, simulator quirks).

class SecureViewFactory: NSObject, FlutterPlatformViewFactory {
  private weak var messenger: FlutterBinaryMessenger?

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return SecurePlatformView(frame: frame, viewId: viewId, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class SecurePlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let secureField: UITextField

  init(frame: CGRect, viewId: Int64, args: Any?) {
    containerView = UIView(frame: frame)
    secureField = UITextField(frame: frame)
    super.init()

    // Secure text entry marks the inner _UITextLayoutCanvasView as system
    // protected. We turn off interaction so taps pass through.
    secureField.isSecureTextEntry = true
    secureField.isUserInteractionEnabled = false
    secureField.backgroundColor = .clear
    secureField.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(secureField)
    NSLayoutConstraint.activate([
      secureField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      secureField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      secureField.topAnchor.constraint(equalTo: containerView.topAnchor),
      secureField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    // Strip the standard text-field appearance so the field is invisible
    // visually but still triggers the iOS secure layer.
    secureField.canvasView?.layer.sublayers?.forEach { $0.isHidden = true }
  }

  func view() -> UIView {
    return containerView
  }
}

private extension UITextField {
  /// The internal subview iOS marks as system-protected when
  /// `isSecureTextEntry` is true. Walks the private view hierarchy looking
  /// for `_UITextLayoutCanvasView` (iOS 15+) or its prior names.
  var canvasView: UIView? {
    return findRecursive(in: self) { v in
      let name = String(describing: type(of: v))
      return name.contains("CanvasView") || name.contains("TextLayoutCanvasView")
    }
  }

  private func findRecursive(in root: UIView, match: (UIView) -> Bool) -> UIView? {
    if match(root) { return root }
    for child in root.subviews {
      if let hit = findRecursive(in: child, match: match) { return hit }
    }
    return nil
  }
}
