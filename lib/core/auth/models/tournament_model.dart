import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String name;
  final String stage;
  final int currentRound;
  final int totalRounds;
  final bool knockoutStarted;
  bool registrationOpen; // Remove final keyword
  final String gender;
  final String level;
  final String location;

  Tournament({
    required this.id,
    required this.name,
    required this.stage,
    required this.currentRound,
    required this.totalRounds,
    required this.knockoutStarted,
    required this.registrationOpen,
    required this.gender,
    required this.level,
    required this.location,
  });

  factory Tournament.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      name: data['name'] ?? '',
      stage: data['stage'] ?? '',
      currentRound: data['currentRound'] ?? 0,
      totalRounds: data['totalRounds'] ?? 0,
      knockoutStarted: data['knockoutStarted'] ?? false,
      registrationOpen: data['registrationOpen'] ?? true,
      gender: data['gender'] ?? '',
      level: data['level'] ?? '',
      location: data['location'] ?? '',
    );
  }

  factory Tournament.fromMap(Map<String, dynamic> data, String documentId) {
    return Tournament(
      id: documentId,
      name: data['name'] ?? '',
      stage: data['stage'] ?? '',
      currentRound: data['currentRound'] ?? 0,
      totalRounds: data['totalRounds'] ?? 0,
      knockoutStarted: data['knockoutStarted'] ?? false,
      registrationOpen: data['registrationOpen'] ?? true,
      gender: data['gender'] ?? '',
      level: data['level'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'stage': stage,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'knockoutStarted': knockoutStarted,
      'registrationOpen': registrationOpen,
      'gender': gender,
      'level': level,
      'location': location,
    };
  }
}
