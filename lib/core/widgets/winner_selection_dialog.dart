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
                DocumentReference matchDocRef;

                if (widget.poolName == 'knockout') {
                  // Handle knockout matches
                  matchDocRef = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('knockout_matches').doc(widget.matchId);
                } else {
                  // Handle pool matches
                  matchDocRef = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('pools').doc(widget.poolName).collection('pool_matches').doc(widget.matchId);
                }

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
                  // Increment the win count for the selected winner team in pool matches
                  DocumentReference poolDocRef = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('pools').doc(widget.poolName);

                  DocumentSnapshot poolDoc = await poolDocRef.get();
                  if (poolDoc.exists) {
                    Map<String, dynamic> poolData = poolDoc.data() as Map<String, dynamic>;
                    List<String> teams = List<String>.from(poolData['teams']);
                    List<int> wins = List<int>.from(poolData['wins']);
                    int teamIndex = teams.indexOf(selectedWinner!);
                    if (teamIndex != -1) {
                      wins[teamIndex]++;
                      await poolDocRef.update({
                        'wins': wins
                      });
                    }
                  }

                  // Check if all pool matches are completed
                  QuerySnapshot poolMatches = await poolDocRef.collection('pool_matches').get();

                  bool allMatchesCompleted = poolMatches.docs.every((doc) => doc['winner'] != '');

                  if (allMatchesCompleted) {
                    // Create knockout matches if all pool matches are completed
                    await createKnockoutMatches(widget.tournamentId);
                  }
                } else {
                  // Check if all knockout matches in this round are completed
                  QuerySnapshot knockoutMatches = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('knockout_matches').get();

                  bool allKnockoutMatchesCompleted = knockoutMatches.docs.every((doc) => doc['winner'] != '');

                  if (allKnockoutMatchesCompleted) {
                    // Create the next set of knockout matches or finalize standings if final match is completed
                    await createNextKnockoutMatchesOrFinalize(widget.tournamentId);
                  }
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

  for (var match in knockoutMatchesSnapshot.docs) {
    winners.add(match['winner']);
    String loser = (match['team1'] == match['winner']) ? match['team2'] : match['team1'];
    losers.add(loser);
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

    // Winner and loser of the final
    finalStandings.add({
      'team': winners[0],
      'position': 1
    });
    finalStandings.add({
      'team': losers[0],
      'position': 2
    });

    // Teams that lost in the semi-finals
    finalStandings.add({
      'team': losers[1],
      'position': 3
    });
    finalStandings.add({
      'team': losers[2],
      'position': 3
    });

    // Teams that lost in the quarter-finals
    int quarterFinalLosersCount = 0;
    for (int i = 3; i < losers.length; i++) {
      finalStandings.add({
        'team': losers[i],
        'position': 5
      });
      quarterFinalLosersCount++;
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
    int startPosition = 5 + quarterFinalLosersCount;
    int nextPosition = startPosition + 2;

    for (int i = 0; i < nonKnockoutTeams.length; i++) {
      finalStandings.add({
        'team': nonKnockoutTeams[i]['team'],
        'position': startPosition
      });
      if ((i + 1) % 2 == 0) {
        startPosition = nextPosition;
        nextPosition += 2;
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