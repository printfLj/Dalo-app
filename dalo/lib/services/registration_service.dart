import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/registration.dart';
import 'auth_service.dart' show kAllowedEmailDomains;

/// Result returned from a QR scan/check-in attempt.
class CheckInResult {
  final bool success;
  final String message;
  final String? studentName;
  final String? eventTitle;

  const CheckInResult({
    required this.success,
    required this.message,
    this.studentName,
    this.eventTitle,
  });
}

/// Registration and attendance operations backed by Firestore transactions.
/// Security Rules require the event counter and registration to be written
/// atomically, and only the event owner or a facilitator can check attendees in.
class RegistrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _regs =>
      _db.collection('registrations');

  /// Register the verified account for an event without exceeding capacity.
  Future<Registration> registerForEvent({required String eventId}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to register.');
    if (!user.emailVerified) {
      throw StateError('Verify your student email before registering.');
    }

    final email = (user.email ?? '').trim().toLowerCase();
    final allowed = kAllowedEmailDomains.any(
      (domain) => email.endsWith('@$domain'),
    );
    if (!allowed) {
      throw StateError('Use an @udd.edu.ph or @cdd.edu.ph email address.');
    }

    final userRef = _db.collection('users').doc(user.uid);
    final profile = await userRef.get();
    final profileData = profile.data();
    if (!profile.exists) {
      throw StateError('Your account profile could not be found.');
    }

    final studentName = (profileData?['displayName'] as String? ?? '').trim();
    if (studentName.isEmpty || email.isEmpty) {
      throw StateError('Your account profile is incomplete.');
    }

    final registrationId = '${eventId}_${user.uid}';
    final registrationRef = _regs.doc(registrationId);
    final eventRef = _db.collection('events').doc(eventId);
    final qrToken = _newQrToken();

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(registrationRef);
      final event = await transaction.get(eventRef);

      if (existing.exists) {
        throw StateError('You are already registered for this event.');
      }
      if (!event.exists) throw StateError('Event not found.');

      final data = event.data()!;
      if (data['organizerUid'] == user.uid ||
          profileData?['role'] == 'facilitator') {
        throw StateError(
            'Event hosts and facilitators manage events instead of registering.');
      }
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final registeredCount = (data['registeredCount'] as num?)?.toInt() ?? 0;
      if (capacity <= 0 || registeredCount >= capacity) {
        throw StateError('This event is full. Registration is closed.');
      }

      transaction.set(registrationRef, {
        'eventId': eventId,
        'studentUid': user.uid,
        'studentName': studentName,
        'studentEmail': email,
        'qrToken': qrToken,
        'status': 'registered',
        'registeredAt': FieldValue.serverTimestamp(),
        'checkedInAt': null,
      });
      transaction.update(eventRef, {'registeredCount': registeredCount + 1});
    });

    final saved = await registrationRef.get();
    return Registration.fromDoc(saved);
  }

  String _newQrToken() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Stream of registrations for the current student.
  Stream<List<Registration>> studentRegistrationsStream(String studentUid) {
    return _regs
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Registration.fromDoc).toList());
  }

  /// Single registration by ID.
  Stream<Registration?> registrationStream(String registrationId) {
    return _regs.doc(registrationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Registration.fromDoc(doc);
    });
  }

  /// All registrations for an event owner or facilitator.
  Stream<List<Registration>> eventRegistrationsStream(String eventId) {
    return _regs
        .where('eventId', isEqualTo: eventId)
        .orderBy('studentName')
        .snapshots()
        .map((snap) => snap.docs.map(Registration.fromDoc).toList());
  }

  /// Find the registration by its opaque QR token, then check it in once.
  Future<CheckInResult> checkInByQrToken({
    required String qrToken,
    required String expectedEventId,
  }) async {
    if (qrToken.trim().isEmpty) {
      return const CheckInResult(success: false, message: 'Invalid QR code.');
    }
    try {
      final matches = await _regs
          .where('eventId', isEqualTo: expectedEventId)
          .where('qrToken', isEqualTo: qrToken.trim())
          .limit(1)
          .get();
      if (matches.docs.isEmpty) {
        return const CheckInResult(
          success: false,
          message: 'QR code not found.',
        );
      }
      return await _checkInDocument(
        matches.docs.first.reference,
        expectedEventId,
      );
    } on FirebaseException catch (error) {
      return _checkInError(error);
    } catch (_) {
      return const CheckInResult(
        success: false,
        message: 'Check-in failed. Please try again.',
      );
    }
  }

  /// Manual check-in by registration ID (event owner or facilitator).
  Future<CheckInResult> checkInByRegistrationId({
    required String registrationId,
    required String expectedEventId,
  }) async {
    return _checkInDocument(_regs.doc(registrationId), expectedEventId);
  }

  Future<CheckInResult> _checkInDocument(
    DocumentReference<Map<String, dynamic>> registrationRef,
    String expectedEventId,
  ) async {
    try {
      return await _db.runTransaction((transaction) async {
        final registration = await transaction.get(registrationRef);
        if (!registration.exists) {
          return const CheckInResult(
            success: false,
            message: 'Registration not found.',
          );
        }

        final data = registration.data()!;
        if (data['eventId'] != expectedEventId) {
          return const CheckInResult(
            success: false,
            message: 'QR code is for a different event.',
          );
        }
        if (data['status'] == 'checkedIn') {
          return CheckInResult(
            success: false,
            message: 'Already checked in.',
            studentName: data['studentName'] as String?,
          );
        }

        final eventRef = _db.collection('events').doc(expectedEventId);
        final event = await transaction.get(eventRef);
        if (!event.exists) {
          return const CheckInResult(
            success: false,
            message: 'Event not found.',
          );
        }

        transaction.update(registrationRef, {
          'status': 'checkedIn',
          'checkedInAt': FieldValue.serverTimestamp(),
        });
        return CheckInResult(
          success: true,
          message: 'Attendance confirmed.',
          studentName: data['studentName'] as String?,
          eventTitle: event.data()?['title'] as String?,
        );
      });
    } on FirebaseException catch (error) {
      return _checkInError(error);
    } catch (_) {
      return const CheckInResult(
        success: false,
        message: 'Check-in failed. Please try again.',
      );
    }
  }

  CheckInResult _checkInError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return const CheckInResult(
        success: false,
        message: 'You do not have permission to check in attendees.',
      );
    }
    if (error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed') {
      return const CheckInResult(
        success: false,
        message: 'Network error. Check your connection and try again.',
      );
    }
    return CheckInResult(
      success: false,
      message: error.message ?? 'Check-in failed. Please try again.',
    );
  }

  /// Direct document lookup works because registration IDs are event + UID.
  Future<Registration?> findStudentRegistration({
    required String eventId,
    required String studentUid,
  }) async {
    final doc = await _regs.doc('${eventId}_$studentUid').get();
    if (!doc.exists) return null;
    return Registration.fromDoc(doc);
  }
}
