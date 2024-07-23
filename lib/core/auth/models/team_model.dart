import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String player1;
  final String player2;
  final String ukbtno1;
  final String ukbtno2;

  Team({
    required this.id,
    required this.player1,
    required this.player2,
    required this.ukbtno1,
    required this.ukbtno2,
  });

  factory Team.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      player1: data['player1'],
      player2: data['player2'],
      ukbtno1: data['ukbtno1'],
      ukbtno2: data['ukbtno2'],
    );
  }
}
