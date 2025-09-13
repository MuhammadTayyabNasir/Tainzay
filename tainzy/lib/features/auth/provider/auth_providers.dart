// lib/features/auth/providers/auth_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/repositories/repositories.dart';

// REFACTORED: This provider now only exposes the auth statechanges stream.
// It watches the `authRepositoryProvider` from the repository layer.

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});