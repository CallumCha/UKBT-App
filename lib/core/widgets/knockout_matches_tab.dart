import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/widgets/winner_selection_dialog.dart'; // Import the WinnerSelectionDialog

class KnockoutMatchesTab extends StatefulWidget {
  final String tournamentId;

  const KnockoutMatchesTab({Key? key, required this.tournamentId}) : super(key: key);

  @override
  _KnockoutMatchesTabState createState() => _KnockoutMatchesTabState();
}

class _KnockoutMatchesTabState extends State<KnockoutMatchesTab> {
  void _selectWinnerDialog(String matchId, String team1Id, String team2Id, String team1Name, String team2Name) async {
    String? selectedWinner = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return WinnerSelectionDialog(
          tournamentId: widget.tournamentId,
          poolName: 'knockout', // Identifier for knockout matches
          matchId: matchId,
          team1Id: team1Id,
          team2Id: team2Id,
          team1Name: team1Name,
          team2Name: team2Name,
        );
      },
    );

    if (selectedWinner != null) {
      setState(() {}); // Refresh the state to reflect the change
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('knockout_matches').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No knockout matches available'));
        }
        final matches = snapshot.data!.docs;

        Map<String, List<Map<String, dynamic>>> matchesByRound = {};
        for (var match in matches) {
          final data = match.data() as Map<String, dynamic>;
          if (data['round'] == null) {
            continue;
          }
          final round = data['round'] as String;
          if (!matchesByRound.containsKey(round)) {
            matchesByRound[round] = [];
          }
          matchesByRound[round]!.add({
            ...data,
            'matchId': match.id,
          });
        }

        List<String> sortedRounds = matchesByRound.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedRounds.length,
          itemBuilder: (context, index) {
            final round = sortedRounds[index];
            final roundMatches = matchesByRound[round]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    round,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...roundMatches.map((match) {
                  final matchId = match['matchId'] as String?;
                  final team1Id = match['team1'] as String?;
                  final team2Id = match['team2'] as String?;
                  final winner = match['winner'] as String?;

                  if (matchId == null || team1Id == null || team2Id == null) {
                    return const ListTile(title: Text('Incomplete match data'));
                  }

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait([
                      FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('teams').doc(team1Id).get(),
                      FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('teams').doc(team2Id).get(),
                    ]),
                    builder: (context, teamSnapshots) {
                      if (teamSnapshots.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Loading...'));
                      }
                      if (!teamSnapshots.hasData || teamSnapshots.data!.any((teamDoc) => !teamDoc.exists)) {
                        return const ListTile(title: Text('No data'));
                      }
                      final team1Data = teamSnapshots.data![0].data() as Map<String, dynamic>?;
                      final team2Data = teamSnapshots.data![1].data() as Map<String, dynamic>?;

                      if (team1Data == null || team2Data == null) {
                        return const ListTile(title: Text('Incomplete team data'));
                      }

                      final player1Team1 = team1Data['player1'] as String?;
                      final player2Team1 = team1Data['player2'] as String?;
                      final player1Team2 = team2Data['player1'] as String?;
                      final player2Team2 = team2Data['player2'] as String?;

                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: Future.wait([
                          FirebaseFirestore.instance.collection('users').doc(player1Team1).get(),
                          FirebaseFirestore.instance.collection('users').doc(player2Team1).get(),
                          FirebaseFirestore.instance.collection('users').doc(player1Team2).get(),
                          FirebaseFirestore.instance.collection('users').doc(player2Team2).get(),
                        ]),
                        builder: (context, userSnapshots) {
                          if (userSnapshots.connectionState == ConnectionState.waiting) {
                            return const ListTile(title: Text('Loading...'));
                          }
                          if (!userSnapshots.hasData || userSnapshots.data!.any((userDoc) => !userDoc.exists)) {
                            return const ListTile(title: Text('No data'));
                          }

                          final player1NameTeam1 = userSnapshots.data![0].data() as Map<String, dynamic>?;
                          final player2NameTeam1 = userSnapshots.data![1].data() as Map<String, dynamic>?;
                          final player1NameTeam2 = userSnapshots.data![2].data() as Map<String, dynamic>?;
                          final player2NameTeam2 = userSnapshots.data![3].data() as Map<String, dynamic>?;

                          final team1Name = '${player1NameTeam1?['name'] ?? 'No name'} & ${player2NameTeam1?['name'] ?? 'No name'}';
                          final team2Name = '${player1NameTeam2?['name'] ?? 'No name'} & ${player2NameTeam2?['name'] ?? 'No name'}';

                          bool isTeam1Winner = winner == team1Id;
                          bool isTeam2Winner = winner == team2Id;

                          return ListTile(
                            title: Text(
                              'Match ${index + 1} $round',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: team1Name,
                                    style: TextStyle(
                                      fontWeight: isTeam1Winner ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' vs ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: team2Name,
                                    style: TextStyle(
                                      fontWeight: isTeam2Winner ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: winner == ''
                                ? () {
                                    _selectWinnerDialog(matchId, team1Id, team2Id, team1Name, team2Name);
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }
}
