// lib/app/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- REPOSITORY: AUTHENTICATION ---
// This class abstracts the data source (Firebase Auth) for authentication.
// It handles all auth-related operations like sign-in, sign-out, and state changes.

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  AuthRepository(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException code: ${e.code}');
      }
      switch (e.code) {
        case 'user-not-found': return 'No user found for that email.';
        case 'wrong-password': return 'Wrong password provided for that user.';
        case 'invalid-email': return 'The email address is not valid.';
        case 'user-disabled': return 'This user account has been disabled.';
        case 'invalid-credential': return 'Invalid credentials. Please check your email and password.';
        case 'network-request-failed': return 'A network error occurred. Please check your connection.';
        default: return 'An unexpected error occurred: ${e.code}.';
      }
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
}

// --- PROVIDERS ---

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});