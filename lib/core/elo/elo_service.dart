import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Import the dart:math library

class ELOService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateELO(String tournamentId, String team1Id, String team2Id, bool team1Wins) async {
    final tournamentDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
    if (!tournamentDoc.exists) return;

    final tournamentData = tournamentDoc.data()!;
    final List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from(tournamentData['teams']);

    final team1 = teams.firstWhere((team) => team['teamId'] == team1Id);
    final team2 = teams.firstWhere((team) => team['teamId'] == team2Id);

    final player1a = team1['ukbtno1'];
    final player1b = team1['ukbtno2'];
    final player2a = team2['ukbtno1'];
    final player2b = team2['ukbtno2'];

    final elo1a = await _getPlayerELO(player1a);
    final elo1b = await _getPlayerELO(player1b);
    final elo2a = await _getPlayerELO(player2a);
    final elo2b = await _getPlayerELO(player2b);

    final team1ELO = (elo1a + elo1b) / 2;
    final team2ELO = (elo2a + elo2b) / 2;

    final expectedScore1 = _expectedScore(team1ELO, team2ELO);
    final expectedScore2 = _expectedScore(team2ELO, team1ELO);

    final kFactor = 30; // Example K-factor

    final newTeam1ELO = team1ELO + kFactor * ((team1Wins ? 1 : 0) - expectedScore1);
    final newTeam2ELO = team2ELO + kFactor * ((team1Wins ? 0 : 1) - expectedScore2);

    final newElo1a = elo1a + (newTeam1ELO - team1ELO);
    final newElo1b = elo1b + (newTeam1ELO - team1ELO);
    final newElo2a = elo2a + (newTeam2ELO - team2ELO);
    final newElo2b = elo2b + (newTeam2ELO - team2ELO);

    await _updatePlayerELO(player1a, newElo1a);
    await _updatePlayerELO(player1b, newElo1b);
    await _updatePlayerELO(player2a, newElo2a);
    await _updatePlayerELO(player2b, newElo2b);
  }

  double _expectedScore(double ratingA, double ratingB) {
    return 1 / (1 + pow(10, (ratingB - ratingA) / 400));
  }

  Future<double> _getPlayerELO(String ukbtno) async {
    final playerDoc = await _firestore.collection('users').doc(ukbtno).get();
    if (!playerDoc.exists) return 1500; // Default ELO
    return playerDoc.data()!['elo'].toDouble();
  }

  Future<void> _updatePlayerELO(String ukbtno, double newELO) async {
    await _firestore.collection('users').doc(ukbtno).update({
      'elo': newELO
    });
  }
}
