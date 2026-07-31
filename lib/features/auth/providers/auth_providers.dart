import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/firebase_providers.dart';
import '../services/auth_services.dart';
import '../models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firestore: ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
final authTransitionInProgressProvider = StateProvider<bool>((ref) => false);

// auth_providers.dart — currentUserProvider becomes a StreamProvider
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.value;
  if (firebaseUser == null) return Stream.value(null);

  return ref
      .watch(authServiceProvider)
      .watchUserData(firebaseUser.uid)
      .map(
        (data) => data == null ? null : AppUser.fromMap(firebaseUser.uid, data),
      );
});
