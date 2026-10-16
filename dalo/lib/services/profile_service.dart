import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveProfile({
    required String displayName,
    required String department,
    required String yearLevel,
    required String gender,
    required String organizations,
    required String? profileImageBase64,
    required bool removeProfileImage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in to edit your profile.');

    final name = displayName.trim();
    if (name.length < 2 || name.length > 40) {
      throw ArgumentError('Your display name must be 2 to 40 characters.');
    }

    await user.updateDisplayName(name);
    final updates = <String, Object?>{
      'displayName': name,
      'department': department.trim(),
      'yearLevel': yearLevel.trim(),
      'gender': gender.trim(),
      'organizations': organizations.trim(),
    };
    if (removeProfileImage) {
      updates['profileImageBase64'] = FieldValue.delete();
    } else if (profileImageBase64 != null) {
      updates['profileImageBase64'] = profileImageBase64;
    }
    await _db.collection('users').doc(user.uid).update(updates);
  }
}
