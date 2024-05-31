import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String name;
  final String location;
  final String level;
  final String gender;
  final DateTime date;
  final List<Map<String, dynamic>> teams;

  Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.level,
    required this.gender,
    required this.date,
    required this.teams,
  });

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Tournament(
      id: doc.id,
      name: data['name'],
      location: data['location'],
      level: data['level'],
      gender: data['gender'],
      date: (data['date'] as Timestamp).toDate(),
      teams: List<Map<String, dynamic>>.from(data['teams']),
    );
  }
}
