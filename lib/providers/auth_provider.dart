import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps [FirebaseAuth] and exposes the current signed-in user as
/// observable state for the rest of the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// `google_sign_in` requires `initialize()` to be called exactly once
  /// before any other method; this future caches that single call.
  Future<void>? _googleSignInInitialization;

  User? get currentUser => _auth.currentUser;

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
  /// Returns silently if the user cancels the account picker.
  Future<void> signInWithGoogle() async {
    _googleSignInInitialization ??= _googleSignIn.initialize();
    await _googleSignInInitialization;

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Пользователь закрыл окно выбора аккаунта.
        return;
      }
      rethrow;
    }

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (_googleSignInInitialization != null) {
      await _googleSignInInitialization;
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
