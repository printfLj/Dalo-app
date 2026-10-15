import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a registration.
enum RegistrationStatus { registered, checkedIn, cancelled }

RegistrationStatus registrationStatusFromString(String? s) {
  switch (s) {
    case 'checkedIn':
      return RegistrationStatus.checkedIn;
    case 'cancelled':
      return RegistrationStatus.cancelled;
    default:
      return RegistrationStatus.registered;
  }
}

class Registration {
  final String id;
  final String eventId;
  final String studentUid;
  final String studentName;
  final String studentEmail;
  /// Opaque, hard-to-guess token. Never contains personal data.
  final String qrToken;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? checkedInAt;

  const Registration({
    required this.id,
    required this.eventId,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.qrToken,
    required this.status,
    required this.registeredAt,
    this.checkedInAt,
  });

  bool get isCheckedIn => status == RegistrationStatus.checkedIn;

  factory Registration.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Registration(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      studentEmail: data['studentEmail'] as String? ?? '',
      qrToken: data['qrToken'] as String? ?? '',
      status: registrationStatusFromString(data['status'] as String?),
      registeredAt:
          (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'studentUid': studentUid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'qrToken': qrToken,
        'status': status.name,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'checkedInAt':
            checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      };
}
