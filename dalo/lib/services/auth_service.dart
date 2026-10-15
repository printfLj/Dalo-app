import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';

/// Student email domains accepted by the app and Firestore Security Rules.
const List<String> kAllowedEmailDomains = ['udd.edu.ph', 'cdd.edu.ph'];

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Returns true only when the email ends with an allowed institution domain.
  bool _isDomainAllowed(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return kAllowedEmailDomains.any(
      (domain) => normalizedEmail.endsWith('@$domain'),
    );
  }

  String get _allowedDomainsMessage =>
      'Use an ${kAllowedEmailDomains.map((domain) => '@$domain').join(' or ')} email address.';

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!_isDomainAllowed(trimmedEmail)) {
      throw Exception(_allowedDomainsMessage);
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    await cred.user!.updateDisplayName(displayName.trim());
    await cred.user!.sendEmailVerification();

    final appUser = AppUser(
      uid: cred.user!.uid,
      email: trimmedEmail,
      displayName: displayName.trim(),
      role: UserRole.student, // Public sign-up always creates student
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(cred.user!.uid).set(appUser.toMap());

    // Keep the new account signed out until its email address is verified.
    await _auth.signOut();

    return appUser;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!_isDomainAllowed(trimmedEmail)) {
      throw Exception(_allowedDomainsMessage);
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    if (credential.user?.emailVerified != true) {
      await credential.user?.sendEmailVerification();
      await _auth.signOut();
      throw Exception('email-not-verified');
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<AppUser?> fetchCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> currentAppUserStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _db
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
    });
  }
}
