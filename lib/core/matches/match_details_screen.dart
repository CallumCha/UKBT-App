import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:ukbtapp/core/tournament/tournament_service.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String tournamentId;
  final String poolId;
  final int matchIndex;
  final TextEditingController _setsController = TextEditingController();

  MatchDetailsScreen({
    required this.tournamentId,
    required this.poolId,
    required this.matchIndex,
  });

  Future<void> _updateMatch(BuildContext context, String sets) async {
    try {
      final poolDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').doc(poolId).get();

      if (!poolDoc.exists) {
        _showMessage(context, 'Pool data not found.');
        return;
      }

      var poolData = poolDoc.data() as Map<String, dynamic>?;
      if (poolData == null) {
        _showMessage(context, 'Pool data not found.');
        return;
      }

      List<Map<String, dynamic>> matchesInPool = List<Map<String, dynamic>>.from(poolData['matches'] ?? []);
      if (matchIndex >= matchesInPool.length) {
        _showMessage(context, 'Match data not found.');
        return;
      }

      var match = matchesInPool[matchIndex];
      if (match['status'] == 'played') {
        _showMessage(context, 'This match has already been played.');
        return;
      }

      var team1 = match['team1'];
      var team2 = match['team2'];

      List<int> setsScores = sets.split(':').map(int.parse).toList();
      if (setsScores.length != 2) {
        _showMessage(context, 'Invalid sets format. Use "X:Y" format.');
        return;
      }

      int setsWonByTeam1 = setsScores[0];
      int setsWonByTeam2 = setsScores[1];

      match['sets'] = sets;
      match['status'] = 'played';

      team1['gamesWon'] = (team1['gamesWon'] ?? 0) as int;
      team1['gamesLost'] = (team1['gamesLost'] ?? 0) as int;
      team2['gamesWon'] = (team2['gamesWon'] ?? 0) as int;
      team2['gamesLost'] = (team2['gamesLost'] ?? 0) as int;

      if (setsWonByTeam1 > setsWonByTeam2) {
        team1['gamesWon'] += 1;
        team2['gamesLost'] += 1;
      } else {
        team2['gamesWon'] += 1;
        team1['gamesLost'] += 1;
      }

      _updateEloRatings(team1, team2, setsWonByTeam1 > setsWonByTeam2);

      matchesInPool[matchIndex] = match;
      await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').doc(poolId).update({
        'matches': matchesInPool
      });

      // Update the teams array in the tournament
      await _updateTeams(tournamentId, team1, team2);

      _showMessage(context, 'Match updated successfully.');
    } catch (e) {
      _showMessage(context, 'Failed to update match: $e');
    }
  }

  Future<void> _updateTeams(String tournamentId, Map<String, dynamic> team1, Map<String, dynamic> team2) async {
    final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
    if (!tournamentDoc.exists) return;

    var tournamentData = tournamentDoc.data() as Map<String, dynamic>?;
    if (tournamentData == null) return;

    List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from(tournamentData['teams'] ?? []);
    teams = teams.map((team) {
      if (team['teamId'] == team1['teamId']) return team1;
      if (team['teamId'] == team2['teamId']) return team2;
      return team;
    }).toList();

    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
      'teams': teams
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateEloRatings(Map<String, dynamic> team1, Map<String, dynamic> team2, bool team1Won) {
    double K = 32.0;

    double team1Elo = team1['elo'];
    double team2Elo = team2['elo'];

    double expectedScoreTeam1 = 1 / (1 + math.pow(10, (team2Elo - team1Elo) / 400));
    double expectedScoreTeam2 = 1 / (1 + math.pow(10, (team1Elo - team2Elo) / 400));

    double actualScoreTeam1 = team1Won ? 1 : 0;
    double actualScoreTeam2 = team1Won ? 0 : 1;

    double newTeam1Elo = team1Elo + K * (actualScoreTeam1 - expectedScoreTeam1);
    double newTeam2Elo = team2Elo + K * (actualScoreTeam2 - expectedScoreTeam2);

    team1['elo'] = newTeam1Elo;
    team2['elo'] = newTeam2Elo;

    _updatePlayerEloRatings(team1['ukbtno1'], team1['ukbtno2'], newTeam1Elo);
    _updatePlayerEloRatings(team2['ukbtno1'], team2['ukbtno2'], newTeam2Elo);
  }

  void _updatePlayerEloRatings(int ukbtno1, int ukbtno2, double teamElo) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    final player1Doc = await usersRef.where('ukbtno', isEqualTo: ukbtno1).get();
    if (player1Doc.docs.isNotEmpty) {
      var player1 = player1Doc.docs.first;
      await usersRef.doc(player1.id).update({
        'elo': teamElo
      });
    }

    final player2Doc = await usersRef.where('ukbtno', isEqualTo: ukbtno2).get();
    if (player2Doc.docs.isNotEmpty) {
      var player2 = player2Doc.docs.first;
      await usersRef.doc(player2.id).update({
        'elo': teamElo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').doc(poolId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var poolData = snapshot.data!.data() as Map<String, dynamic>?;
          if (poolData == null) {
            return Center(child: Text('Pool data not found.'));
          }

          List<Map<String, dynamic>> matchesInPool = List<Map<String, dynamic>>.from(poolData['matches'] ?? []);
          if (matchIndex >= matchesInPool.length) {
            return Center(child: Text('Match data not found.'));
          }

          var match = matchesInPool[matchIndex];
          var team1 = match['team1'];
          var team2 = match['team2'];

          bool isPlayed = match['status'] == 'played';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teams: ${team1['ukbtno1']} & ${team1['ukbtno2']} vs ${team2['ukbtno1']} & ${team2['ukbtno2']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _setsController,
                  decoration: InputDecoration(labelText: 'Sets (e.g., 3:1)'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isPlayed ? null : () => _updateMatch(context, _setsController.text),
                  child: Text('Update Match'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
