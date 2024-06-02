import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/pool_model.dart';

class ScoreUpdater {
  final String tournamentId;

  ScoreUpdater(this.tournamentId);

  Future<void> updateMatchResult(
    Pool pool,
    int matchIndex,
    int team1Sets,
    int team2Sets,
  ) async {
    final match = pool.matches[matchIndex];
    match['result'] = {
      'setsTeam1': team1Sets,
      'setsTeam2': team2Sets,
    };

    _updateStandings(pool, match['team1'] as Map<String, dynamic>, match['team2'] as Map<String, dynamic>, team1Sets, team2Sets);

    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
      'pools': pool.toMap(),
    });
  }

  void _updateStandings(Pool pool, Map<String, dynamic> team1, Map<String, dynamic> team2, int team1Sets, int team2Sets) {
    final standings = pool.standings;
    final team1Standing = standings.firstWhere((standing) => standing['team'] == team1);
    final team2Standing = standings.firstWhere((standing) => standing['team'] == team2);

    team1Standing['mp'] = (team1Standing['mp'] ?? 0) + 1;
    team2Standing['mp'] = (team2Standing['mp'] ?? 0) + 1;

    if (team1Sets > team2Sets) {
      team1Standing['w'] = (team1Standing['w'] ?? 0) + 1;
      team2Standing['l'] = (team2Standing['l'] ?? 0) + 1;
    } else {
      team1Standing['l'] = (team1Standing['l'] ?? 0) + 1;
      team2Standing['w'] = (team2Standing['w'] ?? 0) + 1;
    }

    team1Standing['sWon'] = (team1Standing['sWon'] ?? 0) + team1Sets;
    team1Standing['sLost'] = (team1Standing['sLost'] ?? 0) + team2Sets;
    team2Standing['sWon'] = (team2Standing['sWon'] ?? 0) + team2Sets;
    team2Standing['sLost'] = (team2Standing['sLost'] ?? 0) + team1Sets;

    standings.sort((a, b) {
      final int winsA = a['w'] ?? 0;
      final int winsB = b['w'] ?? 0;
      if (winsA != winsB) {
        return winsB.compareTo(winsA);
      }
      final int setsDiffA = (a['sWon'] ?? 0) - (a['sLost'] ?? 0);
      final int setsDiffB = (b['sWon'] ?? 0) - (b['sLost'] ?? 0);
      return setsDiffB.compareTo(setsDiffA);
    });
  }
}
