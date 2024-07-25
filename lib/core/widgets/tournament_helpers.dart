import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createKnockoutMatches(String tournamentId) async {
  final poolsSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').get();
  List<Map<String, dynamic>> standings = [];

  for (var pool in poolsSnapshot.docs) {
    List<String> teams = List<String>.from(pool['teams']);
    List<int> wins = List<int>.from(pool['wins']);
    for (int i = 0; i < teams.length; i++) {
      standings.add({
        'team': teams[i],
        'wins': wins[i]
      });
    }
  }

  // Sort teams based on wins
  standings.sort((a, b) => b['wins'].compareTo(a['wins']));

  // Select top teams for knockout stage
  List<String> topTeams;
  if (standings.length <= 4) {
    topTeams = standings.take(4).map((entry) => entry['team'] as String).toList();
  } else {
    topTeams = standings.take(8).map((entry) => entry['team'] as String).toList();
  }

  // Create knockout brackets
  List<List<String>> knockoutBrackets = [];
  while (topTeams.length >= 2) {
    knockoutBrackets.add([
      topTeams.removeAt(0),
      topTeams.removeAt(topTeams.length - 1)
    ]);
  }

  // Add knockout matches to Firestore
  for (int i = 0; i < knockoutBrackets.length; i++) {
    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').add({
      'team1': knockoutBrackets[i][0],
      'team2': knockoutBrackets[i][1],
      'winner': '',
      'round': 1,
    });
  }
}
