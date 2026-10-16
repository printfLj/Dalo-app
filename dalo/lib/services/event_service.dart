import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _events => _db.collection('events');

  /// Create an event owned by the currently signed-in verified account.
  Future<String> createEvent(Event event) async {
    if (event.capacity < 1 || event.capacity > Event.maximumCapacity) {
      throw ArgumentError(
          'Event capacity must be between 1 and ${Event.maximumCapacity}.');
    }
    final eventData = event.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _events.add(eventData);
    return ref.id;
  }

  /// Permanently remove an event and its registrations. Mark it as deleting
  /// first so the registration rules reject new joins while cleanup runs.
  Future<void> deleteEvent(String eventId) async {
    final eventRef = _events.doc(eventId);
    await eventRef.update({'deleting': true});

    while (true) {
      final registrations = await _db
          .collection('registrations')
          .where('eventId', isEqualTo: eventId)
          .limit(400)
          .get();
      if (registrations.docs.isEmpty) break;

      final batch = _db.batch();
      for (final registration in registrations.docs) {
        batch.delete(registration.reference);
      }
      await batch.commit();
    }

    await eventRef.delete();
  }

  /// Stream of all upcoming events, ordered by date.
  Stream<List<Event>> eventsStream() {
    return _events
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Event.fromDoc).toList());
  }

  Stream<List<Event>> hostedEventsStream(String organizerUid) {
    return _events
        .where('organizerUid', isEqualTo: organizerUid)
        .snapshots()
        .map((snap) {
      final events = snap.docs.map(Event.fromDoc).toList();
      events.sort((a, b) => b.date.compareTo(a.date));
      return events;
    });
  }

  /// Single event snapshot.
  Stream<Event?> eventStream(String eventId) {
    return _events.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Event.fromDoc(doc);
    });
  }

  Future<Event?> getEvent(String eventId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromDoc(doc);
  }
}
