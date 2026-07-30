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

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);

  final firebaseUser = authState.value;
  if (firebaseUser == null) return null;

  final data = await ref
      .watch(authServiceProvider)
      .fetchUserData(firebaseUser.uid);
  if (data == null) return null;
  return AppUser.fromMap(firebaseUser.uid, data);
});
