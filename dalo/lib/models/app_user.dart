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
  final String department;
  final String yearLevel;
  final String gender;
  final String organizations;
  final String? profileImageBase64;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.department = '',
    this.yearLevel = '',
    this.gender = '',
    this.organizations = '',
    this.profileImageBase64,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: userRoleFromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      department: data['department'] as String? ?? '',
      yearLevel: data['yearLevel'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      organizations: data['organizations'] as String? ?? '',
      profileImageBase64: data['profileImageBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
