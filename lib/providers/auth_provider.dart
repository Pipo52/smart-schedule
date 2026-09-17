import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Wraps [FirebaseAuth] and exposes the current signed-in user as
/// observable state for the rest of the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
