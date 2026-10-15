import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles a user can hold. Stored in Firestore under users/{uid}.role.
enum UserRole { student, organizer, facilitator }

UserRole userRoleFromString(String? s) {
  switch (s) {
    case 'organizer':
      return UserRole.organizer;
    case 'facilitator':
      return UserRole.facilitator;
    default:
      return UserRole.student;
  }
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: userRoleFromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
