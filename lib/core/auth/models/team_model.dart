import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  String user1;
  String user2;

  Team({
    required this.id,
    required this.user1,
    required this.user2,
  });

  factory Team.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      user1: data['player1'] ?? '',
      user2: data['player2'] ?? '',
    );
  }
}
