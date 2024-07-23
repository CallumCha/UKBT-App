import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/widgets/tournament_helpers.dart'; // Import the helper functions

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
            if (selectedWinner != null) {
              try {
                DocumentReference matchDocRef = getMatchDocRef(widget.tournamentId, widget.poolName, widget.matchId);

                // Check if the document exists
                DocumentSnapshot matchDoc = await matchDocRef.get();
                if (!matchDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Match document not found: ${widget.matchId}')),
                  );
                  return;
                }

                await matchDocRef.update({
                  'winner': selectedWinner
                });

                if (widget.poolName != 'knockout') {
                  await updatePoolMatches(widget.tournamentId, selectedWinner!);
                } else {
                  await updateKnockoutMatch(widget.tournamentId);
                }

                Navigator.of(context).pop(selectedWinner);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
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

    if (allKnockoutMatchesCompleted) {
      await createNextKnockoutMatchesOrFinalize(tournamentId);

      // Force an update to the tournament document to trigger the stream
      await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print("All knockout matches completed, tournament updated"); // Debug print
      Navigator.of(context).pop(selectedWinner);
    } else {
      print("Not all knockout matches are completed yet"); // Debug print
    }
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

  List<String> winners = [];
  List<String> losers = [];
  Map<String, String> roundInfo = {};

  for (var match in knockoutMatchesSnapshot.docs) {
    winners.add(match['winner']);
    String loser = (match['team1'] == match['winner']) ? match['team2'] : match['team1'];
    losers.add(loser);
    roundInfo[match['winner']] = match['round'];
    roundInfo[loser] = match['round'];
  }

  // Determine the next round name and the number of matches
  String nextRoundName;
  double numMatches = winners.length / 2;

  if (numMatches == 4) {
    nextRoundName = 'Quarter Finals';
  } else if (numMatches == 2) {
    nextRoundName = 'Semi Finals';
  } else if (numMatches == 1) {
    nextRoundName = 'Final';
  } else {
    // Create final standings if all rounds are completed
    List<Map<String, dynamic>> finalStandings = [];

    // Winner of the final
    finalStandings.add({
      'team': winners[0],
      'position': 1
    });

    // Runner-up (loser of the final)
    String runnerUp = losers.firstWhere((loser) => roundInfo[loser] == 'Final');
    finalStandings.add({
      'team': runnerUp,
      'position': 2
    });

    // Semi-finalists (3rd place)
    List<String> semiFinalLosers = losers.where((loser) => roundInfo[loser] == 'Semi Finals').toList();
    for (var semifinalist in semiFinalLosers) {
      finalStandings.add({
        'team': semifinalist,
        'position': 3
      });
    }

    // Quarter-finalists (5th place)
    List<String> quarterFinalLosers = losers.where((loser) => roundInfo[loser] == 'Quarter Finals').toList();
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
        if (!winners.contains(teams[i]) && !losers.contains(teams[i])) {
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

    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
      'final_standings': finalStandings,
    });
    return; // No more rounds to create
  }

  // Create the next round of knockout matches
  List<List<String>> nextRoundMatches = [];
  while (winners.length >= 2) {
    nextRoundMatches.add([
      winners.removeAt(0),
      winners.removeAt(winners.length - 1)
    ]);
  }

  for (var i = 0; i < nextRoundMatches.length; i++) {
    await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('knockout_matches').add({
      'team1': nextRoundMatches[i][0],
      'team2': nextRoundMatches[i][1],
      'winner': '',
      'round': nextRoundName,
    });
  }
}
