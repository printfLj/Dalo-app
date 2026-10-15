import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _events => _db.collection('events');

  /// Create an event owned by the currently signed-in verified account.
  Future<String> createEvent(Event event) async {
    final ref = await _events.add(event.toMap());
    return ref.id;
  }

  /// Stream of all upcoming events, ordered by date.
  Stream<List<Event>> eventsStream() {
    return _events
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Event.fromDoc).toList());
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
