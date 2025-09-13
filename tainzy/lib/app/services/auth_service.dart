// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class AuthService {
  final FirebaseAuth _firebaseAuth;
  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      // NEW: Log the actual error code to the console for debugging
      if (kDebugMode) {
        print('FirebaseAuthException code: ${e.code}');
      }

      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided for that user.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
      // NEW: Handle a common web-specific error
        case 'network-request-failed':
          return 'A network error occurred. Please check your connection.';
        default:
        // NEW: Include the error code in the UI for better feedback
          return 'An unexpected error occurred: ${e.code}.';
      }
    } catch (e) {
      // Catch any other potential errors
      return 'An error occurred. Please check your internet connection and try again.';
    }
  }
}