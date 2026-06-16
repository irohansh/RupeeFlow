import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Email/Password ───────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    await _checkLoginLockout();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await _resetLoginAttempts();
      return cred;
    } on FirebaseAuthException {
      await _incrementLoginAttempts();
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    await cred.user?.sendEmailVerification();
    await _createUserDocument(cred.user!);
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _checkPasswordResetLimit();
    await _auth.sendPasswordResetEmail(email: email);
    await _incrementPasswordResetCount();
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    if (userCred.additionalUserInfo?.isNewUser ?? false) {
      await _createUserDocument(userCred.user!);
    }
    return userCred;
  }

  // ─── User Document ────────────────────────────────────────────────────────

  Future<void> _createUserDocument(User user) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({...user.toFirestore(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ─── PIN Security ─────────────────────────────────────────────────────────

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _secureStorage.write(key: AppConstants.pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: AppConstants.pinHashKey);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  Future<bool> hasPinSet() async {
    final pin = await _secureStorage.read(key: AppConstants.pinHashKey);
    return pin != null;
  }

  Future<void> deletePin() async {
    await _secureStorage.delete(key: AppConstants.pinHashKey);
  }

  // ─── Rate Limiting ────────────────────────────────────────────────────────

  Future<void> _checkLoginLockout() async {
    final lockoutTime = await _secureStorage.read(key: AppConstants.lockoutTimeKey);
    if (lockoutTime != null) {
      final lockout = DateTime.parse(lockoutTime);
      if (DateTime.now().isBefore(lockout)) {
        throw Exception('Account locked. Try again after ${lockout.toLocal()}');
      }
      await _secureStorage.delete(key: AppConstants.lockoutTimeKey);
      await _secureStorage.delete(key: AppConstants.loginAttemptsKey);
    }
  }

  Future<void> _incrementLoginAttempts() async {
    final current = int.tryParse(
            await _secureStorage.read(key: AppConstants.loginAttemptsKey) ?? '0') ??
        0;
    final next = current + 1;
    await _secureStorage.write(
        key: AppConstants.loginAttemptsKey, value: next.toString());
    if (next >= AppConstants.maxFailedLoginAttempts) {
      final lockout = DateTime.now()
          .add(const Duration(minutes: AppConstants.loginLockoutMinutes));
      await _secureStorage.write(
          key: AppConstants.lockoutTimeKey, value: lockout.toIso8601String());
    }
  }

  Future<void> _resetLoginAttempts() async {
    await _secureStorage.delete(key: AppConstants.loginAttemptsKey);
    await _secureStorage.delete(key: AppConstants.lockoutTimeKey);
  }

  Future<void> _checkPasswordResetLimit() async {
    final countStr =
        await _secureStorage.read(key: 'pw_reset_count') ?? '0:${DateTime.now().toIso8601String()}';
    final parts = countStr.split(':');
    final count = int.tryParse(parts[0]) ?? 0;
    final since = DateTime.tryParse(parts.sublist(1).join(':')) ?? DateTime.now();
    if (DateTime.now().difference(since).inHours < 1 &&
        count >= AppConstants.maxPasswordResetPerHour) {
      throw Exception('Too many password reset requests. Try again later.');
    }
  }

  Future<void> _incrementPasswordResetCount() async {
    final countStr =
        await _secureStorage.read(key: 'pw_reset_count') ?? '0:${DateTime.now().toIso8601String()}';
    final parts = countStr.split(':');
    final count = int.tryParse(parts[0]) ?? 0;
    final since = DateTime.tryParse(parts.sublist(1).join(':')) ?? DateTime.now();
    if (DateTime.now().difference(since).inHours >= 1) {
      await _secureStorage.write(key: 'pw_reset_count', value: '1:${DateTime.now().toIso8601String()}');
    } else {
      await _secureStorage.write(
          key: 'pw_reset_count', value: '${count + 1}:${since.toIso8601String()}');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
