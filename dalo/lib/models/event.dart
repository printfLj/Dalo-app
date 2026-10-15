import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final String location;
  final int capacity;
  final int registeredCount;
  final String organizerUid;
  final String organizerName;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.capacity,
    required this.registeredCount,
    required this.organizerUid,
    required this.organizerName,
    required this.createdAt,
  });

  bool get isOpen => registeredCount < capacity;
  bool get isFull => registeredCount >= capacity;
  int get spotsLeft => capacity - registeredCount;

  factory Event.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] as String? ?? '',
      location: data['location'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      registeredCount: (data['registeredCount'] as num?)?.toInt() ?? 0,
      organizerUid: data['organizerUid'] as String? ?? '',
      organizerName: data['organizerName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': Timestamp.fromDate(date),
        'time': time,
        'location': location,
        'capacity': capacity,
        'registeredCount': registeredCount,
        'organizerUid': organizerUid,
        'organizerName': organizerName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
