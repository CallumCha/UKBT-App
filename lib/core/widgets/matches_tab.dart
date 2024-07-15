import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/widgets/winner_selection_dialog.dart'; // Import the new dialog widget

class MatchesTab extends StatefulWidget {
  final String tournamentId;

  const MatchesTab({Key? key, required this.tournamentId}) : super(key: key);

  @override
  _MatchesTabState createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  String? selectedPool;

  void _selectWinnerDialog(String poolName, String matchId, String team1Id, String team2Id, String team1Name, String team2Name) async {
    String? selectedWinner = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return WinnerSelectionDialog(
          tournamentId: widget.tournamentId,
          poolName: poolName, // Identifier for pool matches
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
      future: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('pools').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pools available'));
        }
        final pools = snapshot.data!.docs;

        // Collect all matches from all pools
        List<Future<List<QueryDocumentSnapshot>>> matchFutures = [];
        for (var pool in pools) {
          final poolName = pool.id;
          matchFutures.add(FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).collection('pools').doc(poolName).collection('pool_matches').get().then((snapshot) => snapshot.docs));
        }

        return FutureBuilder<List<List<QueryDocumentSnapshot>>>(
          future: Future.wait(matchFutures),
          builder: (context, matchSnapshots) {
            if (matchSnapshots.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!matchSnapshots.hasData || matchSnapshots.data!.isEmpty) {
              return const Center(child: Text('No matches available'));
            }

            // Organize matches by their match index
            Map<int, List<Map<String, dynamic>>> matchesByIndex = {};
            for (int poolIndex = 0; poolIndex < matchSnapshots.data!.length; poolIndex++) {
              final poolName = pools[poolIndex].id;
              final matches = matchSnapshots.data![poolIndex];
              for (int matchIndex = 0; matchIndex < matches.length; matchIndex++) {
                final match = matches[matchIndex];
                final team1 = match['team1'];
                final team2 = match['team2'];
                final winner = match['winner'];
                matchesByIndex.putIfAbsent(matchIndex, () => []);
                matchesByIndex[matchIndex]!.add({
                  'poolName': poolName,
                  'matchId': match.id,
                  'team1': team1,
                  'team2': team2,
                  'winner': winner,
                });
              }
            }

            // Sort matches by match number
            final sortedMatchIndices = matchesByIndex.keys.toList()..sort();

            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pools.map((pool) {
                      final poolName = pool.id;
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ChoiceChip(
                          label: Text(poolName),
                          selected: selectedPool == poolName,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedPool = selected ? poolName : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: sortedMatchIndices.expand((matchIndex) {
                      final matchGroup = matchesByIndex[matchIndex]!;
                      return matchGroup.where((match) => selectedPool == null || match['poolName'] == selectedPool).map((match) {
                        final poolName = match['poolName'];
                        final matchId = match['matchId'];
                        final team1Id = match['team1'];
                        final team2Id = match['team2'];
                        final winner = match['winner'];
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
                            final team1Data = teamSnapshots.data![0].data() as Map<String, dynamic>;
                            final team2Data = teamSnapshots.data![1].data() as Map<String, dynamic>;
                            final player1Team1 = team1Data['player1'];
                            final player2Team1 = team1Data['player2'];
                            final player1Team2 = team2Data['player1'];
                            final player2Team2 = team2Data['player2'];

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
                                    'Match ${matchIndex + 1} $poolName',
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
                                  onTap: winner == ""
                                      ? () {
                                          _selectWinnerDialog(poolName, matchId, team1Id, team2Id, team1Name, team2Name);
                                        }
                                      : null,
                                );
                              },
                            );
                          },
                        );
                      }).toList();
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
