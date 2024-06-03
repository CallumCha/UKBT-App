import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String tournamentId;
  final String groupId;
  final String stage;
  final int round;
  final String team1;
  final String team2;
  final int score1;
  final int score2;
  final bool completed;
  final DateTime date;

  Match({
    required this.id,
    required this.tournamentId,
    required this.groupId,
    required this.stage,
    required this.round,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.completed,
    required this.date,
  });

  factory Match.fromMap(Map<String, dynamic> map, String id) {
    return Match(
      id: id,
      tournamentId: map['tournamentId'] as String,
      groupId: map['groupId'] as String,
      stage: map['stage'] as String,
      round: map['round'] as int,
      team1: map['team1'] as String,
      team2: map['team2'] as String,
      score1: map['score1'] as int,
      score2: map['score2'] as int,
      completed: map['completed'] as bool,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'groupId': groupId,
      'stage': stage,
      'round': round,
      'team1': team1,
      'team2': team2,
      'score1': score1,
      'score2': score2,
      'completed': completed,
      'date': date,
    };
  }
}
