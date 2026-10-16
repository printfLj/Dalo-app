import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';

/// Student email domains accepted by the app and Firestore Security Rules.
const List<String> kAllowedEmailDomains = ['udd.edu.ph', 'cdd.edu.ph'];

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Includes sign-in/out and user reload/profile updates, so the root gate
  /// reacts immediately when Firebase finishes a login.
  Stream<User?> get authStateChanges => _auth.userChanges();

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

    final firebaseUser = cred.user!;
    final name = displayName.trim();
    try {
      await firebaseUser.updateDisplayName(name);
      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: trimmedEmail,
        displayName: name,
        role: UserRole.student, // Public sign-up always creates student
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(firebaseUser.uid).set({
        ...appUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await firebaseUser.sendEmailVerification();
      return appUser;
    } finally {
      // Also sign out after partial failures so an unverified account cannot
      // remain in an authenticated app session.
      await _auth.signOut();
    }
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
    final signedInUser = credential.user;
    await signedInUser?.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser?.emailVerified != true) {
      try {
        await refreshedUser?.sendEmailVerification();
      } finally {
        await _auth.signOut();
      }
      throw Exception('email-not-verified');
    }

    // Recover a profile if an earlier sign-up was interrupted after Firebase
    // Auth created the account but before Firestore saved its user document.
    final user = _auth.currentUser!;
    final profileRef = _db.collection('users').doc(user.uid);
    final profile = await profileRef.get();
    if (!profile.exists) {
      final name = (user.displayName ?? '').trim();
      if (name.length < 2 || name.length > 40) {
        await _auth.signOut();
        throw Exception('profile-recovery-required');
      }
      final recoveredProfile = AppUser(
        uid: user.uid,
        email: trimmedEmail,
        displayName: name,
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      await profileRef.set({
        ...recoveredProfile.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
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

  Stream<AppUser?> appUserStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
}
