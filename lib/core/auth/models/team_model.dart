import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  String id;
  String name;
  String tournamentId;
  String groupId;
  String user1;
  String user2;
  int elo;

  Team({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.groupId,
    required this.user1,
    required this.user2,
    required this.elo,
  });

  factory Team.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      tournamentId: data['tournamentId'] ?? '',
      groupId: data['groupId'] ?? '',
      user1: data['user1'] ?? '',
      user2: data['user2'] ?? '',
      elo: data['elo'] ?? 0,
    );
  }
}
