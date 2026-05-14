import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:app/core/notifications/fcm_service.dart';

class AuthDatasource {
  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // Apple Sign-In on iOS uses the native ASAuthorization flow and the
    // [webAuthenticationOptions] argument is ignored. On Android (and
    // web) the package falls back to an OAuth web flow that requires a
    // Service ID registered in Apple Developer with:
    //   • "Sign In with Apple" capability enabled
    //   • Return URL = https://affinity-dating-app-cf807.firebaseapp.com/__/auth/handler
    // The Service ID identifier is injected at build time via
    // --dart-define=APPLE_SERVICE_ID=<id> so the same code ships across
    // environments. When unset, [webOpts] stays null and the call falls
    // back to the iOS-only native flow.
    const appleServiceId = String.fromEnvironment(
      'APPLE_SERVICE_ID',
      defaultValue: '',
    );
    WebAuthenticationOptions? webOpts;
    if (appleServiceId.isNotEmpty) {
      webOpts = WebAuthenticationOptions(
        clientId: appleServiceId,
        redirectUri: Uri.parse(
          'https://affinity-dating-app-cf807.firebaseapp.com/__/auth/handler',
        ),
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
      webAuthenticationOptions: webOpts,
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) =>
      FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  static Future<void> signOut() async {
    // Drop the FCM token first so this device stops receiving pushes for
    // the account being signed out of. Non-fatal if it fails.
    try {
      await FcmService.unregister();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
