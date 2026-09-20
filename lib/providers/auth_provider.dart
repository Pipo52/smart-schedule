import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps [FirebaseAuth] and exposes the current signed-in user as
/// observable state for the rest of the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSub = _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
    unawaited(ensureGoogleSignInReady());
  }

  static const String _webClientId =
      '298297468313-r4l1q52edbue4etscdr18nl9ttmau0n9.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;

  /// `google_sign_in` requires `initialize()` to be called exactly once
  /// before any other method; this future caches that single call.
  Future<void>? _googleSignInInitialization;

  User? get currentUser => _auth.currentUser;

  bool get supportsGoogleAuthenticate => _googleSignIn.supportsAuthenticate();

  Future<void> ensureGoogleSignInReady() {
    return _googleSignInInitialization ??= _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(clientId: kIsWeb ? _webClientId : null);
    _googleAuthSub = _googleSignIn.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        await _signInToFirebase(event.user);
      }
    });
  }

  Future<void> _signInToFirebase(GoogleSignInAccount googleUser) async {
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) return;
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with a Google account, linking it to Firebase Auth.
  ///
  /// On web this is a no-op: GIS only allows the official `renderButton`
  /// widget, which reports success via [GoogleSignIn.authenticationEvents].
  /// Returns silently if the user cancels the account picker.
  Future<void> signInWithGoogle() async {
    await ensureGoogleSignInReady();
    if (!_googleSignIn.supportsAuthenticate()) {
      return;
    }

    try {
      await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_googleSignInInitialization != null) {
      await _googleSignInInitialization;
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _googleAuthSub?.cancel();
    super.dispose();
  }
}
