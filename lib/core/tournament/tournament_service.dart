import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentService {
  Stream<QuerySnapshot> getTournamentsStream() {
    return FirebaseFirestore.instance.collection('tournaments').snapshots();
  }

  Stream<DocumentSnapshot> getTournamentStream(String tournamentId) {
    return FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).snapshots();
  }

  Stream<QuerySnapshot> getPoolsStream(String tournamentId) {
    return FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').snapshots();
  }

  Future<void> updatePools(String tournamentId) async {
    final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
    if (!tournamentDoc.exists) return;

    final tournamentData = tournamentDoc.data()!;
    final List<Map<String, dynamic>> teams = List<Map<String, dynamic>>.from((tournamentData['teams'] as List).map((team) => Map<String, dynamic>.from(team)));

    teams.sort((a, b) => b['elo'].compareTo(a['elo'])); // Sort teams by elo in descending order

    final poolSize = 4;
    final numPools = (teams.length / poolSize).ceil();
    final pools = List.generate(numPools, (_) => []);

    // Distribute teams into pools
    for (var i = 0; i < teams.length; i++) {
      pools[i % numPools].add(teams[i]);
    }

    final poolCollection = FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools');
    await poolCollection.get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });

    for (var i = 0; i < pools.length; i++) {
      await poolCollection.add({
        'teams': List<Map<String, dynamic>>.from(pools[i]),
        'matches': _generateMatches(List<Map<String, dynamic>>.from(pools[i])),
      });
    }
  }

  List<Map<String, dynamic>> _generateMatches(List<Map<String, dynamic>> teams) {
    List<Map<String, dynamic>> matches = [];
    DateTime startTime = DateTime.now();

    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add({
          'matchId': '${teams[i]['teamId']}_${teams[j]['teamId']}',
          'team1': teams[i],
          'team2': teams[j],
          'time': startTime.add(Duration(hours: matches.length)).toIso8601String(), // Set match time
          'status': 'toPlay',
        });
      }
    }
    return matches;
  }
}
