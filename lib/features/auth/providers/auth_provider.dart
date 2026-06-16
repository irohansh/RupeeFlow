import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user profile
final currentUserProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.read(authRepositoryProvider).getUserProfile(user.uid);
});

// Auth controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createUserWithEmailPassword(email, password, name);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithGoogle();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access RupeeFlow',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPin(String pin) => _repo.verifyPin(pin);
  Future<void> setPin(String pin) => _repo.setPin(pin);
  Future<bool> hasPinSet() => _repo.hasPinSet();
  Future<void> deletePin() => _repo.deletePin();

  Future<void> sendEmailVerification() => _repo.sendEmailVerification();
  Future<void> reloadUser() => _repo.reloadUser();
  bool get isEmailVerified => _repo.isEmailVerified;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});
