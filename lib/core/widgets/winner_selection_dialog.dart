import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/widgets/tournament_helpers.dart'; // Import the helper functions
import 'package:ukbtapp/core/auth/firestore_service.dart'; // Add this import
import 'package:ukbtapp/core/elo_calculator.dart'; // Import the EloCalculator class

class WinnerSelectionDialog extends StatefulWidget {
  final String tournamentId;
  final String poolName; // Use 'knockout' for knockout matches
  final String matchId;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;

  const WinnerSelectionDialog({
    Key? key,
    required this.tournamentId,
    required this.poolName,
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
  }) : super(key: key);

  @override
  _WinnerSelectionDialogState createState() => _WinnerSelectionDialogState();
}

class _WinnerSelectionDialogState extends State<WinnerSelectionDialog> {
  final FirestoreService _firestoreService = FirestoreService(); // Add this line

  String? selectedWinner;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Winner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RadioListTile<String>(
            title: Text(widget.team1Name),
            value: widget.team1Id,
            groupValue: selectedWinner,
            onChanged: (String? value) {
              setState(() {
                selectedWinner = value;
              });
            },
          ),
          RadioListTile<String>(
            title: Text(widget.team2Name),
            value: widget.team2Id,
            groupValue: selectedWinner,
            onChanged: (String? value) {
              setState(() {
                selectedWinner = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedWinner != null && selectedWinner!.isNotEmpty) {
              await getMatchDocRef(widget.tournamentId, widget.poolName, widget.matchId).update({
                'winner': selectedWinner,
              });

              await _updateMatchResultAndElo(widget.matchId, selectedWinner!);

              if (widget.poolName == 'knockout') {
                await updateKnockoutMatch(widget.tournamentId);
              } else {
                await updatePoolMatches(widget.tournamentId, selectedWinner!);
              }

              Navigator.of(context).pop(selectedWinner);
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  DocumentReference getMatchDocRef(String tournamentId, String poolName, String matchId) {
    if (poolName == 'knockout') {
      return FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').doc(matchId);
    } else {
      return FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').doc(poolName).collection('pool_matches').doc(matchId);
    }
  }

  Future<void> updatePoolMatches(String tournamentId, String selectedWinner) async {
    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(tournamentId);
    final pools = [
      'Pool A',
      'Pool B'
    ]; // List of pool names
    bool allMatchesCompleted = true;

    for (String poolName in pools) {
      DocumentReference poolDocRef = tournamentDoc.collection('pools').doc(poolName);
      DocumentSnapshot poolSnapshot = await poolDocRef.get();

      if (poolSnapshot.exists) {
        Map<String, dynamic> poolData = poolSnapshot.data() as Map<String, dynamic>;
        List<String> teams = List<String>.from(poolData['teams']);
        List<int> wins = List<int>.from(poolData['wins']);
        int teamIndex = teams.indexOf(selectedWinner);
        if (teamIndex != -1) {
          wins[teamIndex]++;
          await poolDocRef.update({
            'wins': wins
          });
        }
      }

      QuerySnapshot poolMatchesSnapshot = await poolDocRef.collection('pool_matches').get();
      bool poolMatchesCompleted = poolMatchesSnapshot.docs.every((doc) => doc['winner'] != '');

      if (!poolMatchesCompleted) {
        allMatchesCompleted = false;
      }
    }

    if (allMatchesCompleted) {
      await createKnockoutMatches(tournamentId);
    }
  }

  Future<void> updateKnockoutMatch(String tournamentId) async {
    QuerySnapshot knockoutMatches = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').get();

    bool allKnockoutMatchesCompleted = knockoutMatches.docs.every((doc) => doc['winner'] != '');

    // Check if the final match exists and is completed
    bool finalMatchCompleted = knockoutMatches.docs.where((doc) => doc['round'] == 'Final').any((doc) => doc['winner'] != '');

    if (allKnockoutMatchesCompleted && finalMatchCompleted) {
      await createNextKnockoutMatchesOrFinalize(tournamentId);

      // Force an update to the tournament document to trigger the stream
      await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(selectedWinner);
    } else if (allKnockoutMatchesCompleted && !finalMatchCompleted) {
      // If all matches except the final are completed, create the final match
      await createFinalMatch(tournamentId);
    } else {}
  }

  Future<void> createFinalMatch(String tournamentId) async {
    QuerySnapshot semifinalMatches = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').where('round', isEqualTo: 'Semi Finals').get();

    List<String> finalists = semifinalMatches.docs.map((doc) => doc['winner'] as String).toList();

    if (finalists.length == 2) {
      await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').add({
        'round': 'Final',
        'team1': finalists[0],
        'team2': finalists[1],
        'winner': '',
      });
      print("Final match created between ${finalists[0]} and ${finalists[1]}");
    } else {
      print("Error: Couldn't determine finalists. Found ${finalists.length} winners in semifinals.");
    }
  }

  Future<void> _updateMatchResultAndElo(String matchId, String winnerId) async {
    print("Starting _updateMatchResultAndElo for match: $matchId, winner: $winnerId");
    final matchDoc = await getMatchDocRef(widget.tournamentId, widget.poolName, matchId).get();
    final matchData = matchDoc.data() as Map<String, dynamic>?;

    if (matchData?.isEmpty ?? true) {
      print('Match document not found or is empty');
      return;
    }

    final team1Id = matchData!['team1'];
    final team2Id = matchData['team2'];

    final team1Doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('teams').doc(team1Id).get();
    final team2Doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('teams').doc(team2Id).get();

    final user1Doc = await FirebaseFirestore.instance.collection('users').doc(team1Doc['player1']).get();
    final user2Doc = await FirebaseFirestore.instance.collection('users').doc(team1Doc['player2']).get();
    final user3Doc = await FirebaseFirestore.instance.collection('users').doc(team2Doc['player1']).get();
    final user4Doc = await FirebaseFirestore.instance.collection('users').doc(team2Doc['player2']).get();

    final user1Elo = user1Doc.data()?.containsKey('elo') == true ? user1Doc['elo'] as int : 1500;
    final user2Elo = user2Doc.data()?.containsKey('elo') == true ? user2Doc['elo'] as int : 1500;
    final user3Elo = user3Doc.data()?.containsKey('elo') == true ? user3Doc['elo'] as int : 1500;
    final user4Elo = user4Doc.data()?.containsKey('elo') == true ? user4Doc['elo'] as int : 1500;

    final team1Elo = (user1Elo + user2Elo) ~/ 2;
    final team2Elo = (user3Elo + user4Elo) ~/ 2;

    final team1Won = winnerId == team1Id;
    final eloChanges = EloCalculator.calculateEloChange(team1Elo, team2Elo, team1Won);

    await matchDoc.reference.update({
      'winner': winnerId,
      'completed': true,
    });

    await _updateUserElo(user1Doc.reference, user1Elo + eloChanges[0], eloChanges[0]);
    await _updateUserElo(user2Doc.reference, user2Elo + eloChanges[0], eloChanges[0]);
    await _updateUserElo(user3Doc.reference, user3Elo + eloChanges[1], eloChanges[1]);
    await _updateUserElo(user4Doc.reference, user4Elo + eloChanges[1], eloChanges[1]);

    print("Finished _updateMatchResultAndElo");
  }

  Future<void> _updateUserElo(DocumentReference userRef, int newElo, int eloChange) async {
    final userData = await userRef.get();
    final data = userData.data() as Map<String, dynamic>?;
    List<Map<String, dynamic>> rankChanges;

    if (data != null && data.containsKey('rankChanges')) {
      rankChanges = List<Map<String, dynamic>>.from(data['rankChanges'] ?? []);
    } else {
      rankChanges = [];
    }

    rankChanges.insert(0, {
      'date': Timestamp.now(),
      'change': eloChange,
    });

    if (rankChanges.length > 30) {
      rankChanges = rankChanges.sublist(0, 30);
    }

    await userRef.update({
      'elo': newElo,
      'rankChanges': rankChanges,
    });
  }
}

Future<void> createKnockoutMatches(String tournamentId) async {
  final poolsSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').get();

  List<Map<String, dynamic>> standings = [];

  for (var pool in poolsSnapshot.docs) {
    List<String> teams = List<String>.from(pool['teams']);
    List<int> wins = List<int>.from(pool['wins']);
    for (int i = 0; i < teams.length; i++) {
      standings.add({
        'team': teams[i],
        'wins': wins[i],
      });
    }
  }

  // Sort teams based on wins
  standings.sort((a, b) => b['wins'].compareTo(a['wins']));

  // Select top two teams from each pool
  List<String> topTeams = [];
  for (var pool in poolsSnapshot.docs) {
    List<String> teams = List<String>.from(pool['teams']);
    List<int> wins = List<int>.from(pool['wins']);
    var poolStandings = [];
    for (int i = 0; i < teams.length; i++) {
      poolStandings.add({
        'team': teams[i],
        'wins': wins[i],
      });
    }
    poolStandings.sort((a, b) => b['wins'].compareTo(a['wins']));
    topTeams.add(poolStandings[0]['team']);
    topTeams.add(poolStandings[1]['team']);
  }

  // Create knockout brackets
  List<List<String>> knockoutBrackets = [];
  while (topTeams.length >= 2) {
    knockoutBrackets.add([
      topTeams.removeAt(0),
      topTeams.removeAt(topTeams.length - 1),
    ]);
  }

  String roundName = knockoutBrackets.length == 4
      ? 'Quarter Finals'
      : knockoutBrackets.length == 2
          ? 'Semi Finals'
          : 'Final';

  // Add knockout matches to Firestore
  for (int i = 0; i < knockoutBrackets.length; i++) {
    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').add({
      'team1': knockoutBrackets[i][0],
      'team2': knockoutBrackets[i][1],
      'winner': '',
      'round': roundName,
    });
  }
}

Future<void> createNextKnockoutMatchesOrFinalize(String tournamentId) async {
  final knockoutMatchesSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').get();

  List<QueryDocumentSnapshot> allMatches = knockoutMatchesSnapshot.docs;

  // Create final standings
  List<Map<String, dynamic>> finalStandings = await createFinalStandings(tournamentId, allMatches);

  // Update the tournament document with final standings
  await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
    'final_standings': finalStandings,
    'status': 'completed'
  });

  print("Final standings created and tournament marked as completed");

  // Update user documents with tournament history
  String tournamentName = await getTournamentName(tournamentId);
  Timestamp date = await getTournamentDate(tournamentId);

  for (var standing in finalStandings) {
    String teamId = standing['team'];
    int position = standing['position'];

    DocumentSnapshot teamDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('teams').doc(teamId).get();

    if (teamDoc.exists) {
      Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
      String player1Id = teamData['player1'];
      String player2Id = teamData['player2'];

      await updateUserTournamentHistory(player1Id, {
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'date': date,
        'position': position,
        'partner': {
          'id': player2Id,
          'name': await getUserName(player2Id)
        }
      });

      await updateUserTournamentHistory(player2Id, {
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'date': date,
        'position': position,
        'partner': {
          'id': player1Id,
          'name': await getUserName(player1Id)
        }
      });
    }
  }

  print("Tournament history updated for all participants");
}

Future<List<Map<String, dynamic>>> createFinalStandings(String tournamentId, List<QueryDocumentSnapshot> allMatches) async {
  List<Map<String, dynamic>> finalStandings = [];
  Map<String, String> roundInfo = {};

  for (var match in allMatches) {
    String winner = match['winner'];
    String loser = match['team1'] == winner ? match['team2'] : match['team1'];
    roundInfo[winner] = match['round'];
    roundInfo[loser] = match['round'];
  }

  // Winner of the final
  finalStandings.add({
    'team': allMatches.firstWhere((match) => match['round'] == 'Final')['winner'],
    'position': 1
  });

  // Runner-up (loser of the final)
  String runnerUp = allMatches.firstWhere((match) => match['round'] == 'Final')['team1'] == finalStandings[0]['team'] ? allMatches.firstWhere((match) => match['round'] == 'Final')['team2'] : allMatches.firstWhere((match) => match['round'] == 'Final')['team1'];
  finalStandings.add({
    'team': runnerUp,
    'position': 2
  });

  // Semi-finalists (3rd place)
  List<String> semiFinalLosers = allMatches.where((match) => match['round'] == 'Semi Finals' && match['winner'] != '').map((match) => match['team1'] == match['winner'] ? match['team2'] : match['team1']).toList().cast<String>();
  for (var semifinalist in semiFinalLosers) {
    finalStandings.add({
      'team': semifinalist,
      'position': 3
    });
  }

  // Quarter-finalists (5th place)
  List<String> quarterFinalLosers = allMatches.where((match) => match['round'] == 'Quarter Finals' && match['winner'] != '').map((match) => match['team1'] == match['winner'] ? match['team2'] : match['team1']).toList().cast<String>();
  for (var quarterfinalist in quarterFinalLosers) {
    finalStandings.add({
      'team': quarterfinalist,
      'position': 5
    });
  }

  // Get pool standings for teams that didn't make the knockout stage
  final poolsSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').get();

  List<Map<String, dynamic>> nonKnockoutTeams = [];

  for (var pool in poolsSnapshot.docs) {
    List<String> teams = List<String>.from(pool['teams']);
    List<int> wins = List<int>.from(pool['wins']);
    for (int i = 0; i < teams.length; i++) {
      if (!finalStandings.any((standing) => standing['team'] == teams[i])) {
        nonKnockoutTeams.add({
          'team': teams[i],
          'wins': wins[i]
        });
      }
    }
  }

  // Sort non-knockout teams based on wins
  nonKnockoutTeams.sort((a, b) => b['wins'].compareTo(a['wins']));

  // Assign positions to non-knockout teams
  int startPosition = 5 + quarterFinalLosers.length;
  for (int i = 0; i < nonKnockoutTeams.length; i++) {
    finalStandings.add({
      'team': nonKnockoutTeams[i]['team'],
      'position': startPosition
    });
    if ((i + 1) % 2 == 0) {
      startPosition += 2;
    }
  }

  return finalStandings;
}

Future<String> getTournamentName(String tournamentId) async {
  DocumentSnapshot tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
  return tournamentDoc['name'];
}

Future<Timestamp> getTournamentDate(String tournamentId) async {
  DocumentSnapshot tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
  return tournamentDoc['date'];
}

Future<String> getUserName(String userId) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return userDoc['name'];
}

Future<void> updateUserTournamentHistory(String userId, Map<String, dynamic> tournamentHistory) async {
  DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
  await userDocRef.update({
    'tournamentHistory': FieldValue.arrayUnion([
      tournamentHistory
    ])
  });
}
