import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/auth/models/team_model.dart';

class PoolsTab extends StatelessWidget {
  final String tournamentId;

  const PoolsTab({Key? key, required this.tournamentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('pools').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pools available'));
        }
        final pools = snapshot.data!.docs;
        return ListView.builder(
          itemCount: pools.length,
          itemBuilder: (context, index) {
            final pool = pools[index];
            final poolName = pool.id;
            final teamIds = List<String>.from(pool['teams']);
            final wins = List<int>.from(pool['wins']);

            // Combine teamIds and wins into a list of maps
            List<Map<String, dynamic>> teamsWithWins = [];
            for (int i = 0; i < teamIds.length; i++) {
              teamsWithWins.add({
                'teamId': teamIds[i],
                'wins': wins[i],
              });
            }

            // Sort teams by number of wins
            teamsWithWins.sort((a, b) => b['wins'].compareTo(a['wins']));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poolName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Position')),
                    DataColumn(label: Text('Team')),
                    DataColumn(label: Text('Wins')),
                  ],
                  rows: teamsWithWins.asMap().entries.map((entry) {
                    final position = entry.key + 1;
                    final teamId = entry.value['teamId'];
                    final winCount = entry.value['wins'];
                    return DataRow(
                      cells: [
                        DataCell(Text('$position')),
                        DataCell(
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('teams').doc(teamId).get(),
                            builder: (context, teamSnapshot) {
                              if (teamSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading...');
                              }
                              if (!teamSnapshot.hasData || teamSnapshot.data?.data() == null) {
                                return const Text('No data');
                              }
                              final teamData = teamSnapshot.data!.data() as Map<String, dynamic>;
                              final player1Id = teamData['player1'];
                              final player2Id = teamData['player2'];
                              return FutureBuilder<List<DocumentSnapshot>>(
                                future: Future.wait([
                                  FirebaseFirestore.instance.collection('users').doc(player1Id).get(),
                                  FirebaseFirestore.instance.collection('users').doc(player2Id).get(),
                                ]),
                                builder: (context, userSnapshots) {
                                  if (userSnapshots.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading...');
                                  }
                                  if (userSnapshots.hasError || userSnapshots.data == null || userSnapshots.data!.any((userDoc) => !userDoc.exists)) {
                                    return const Text('No data');
                                  }
                                  final player1Name = userSnapshots.data![0].data() as Map<String, dynamic>?;
                                  final player2Name = userSnapshots.data![1].data() as Map<String, dynamic>?;
                                  return Text('${player1Name?['name'] ?? 'No name'} & ${player2Name?['name'] ?? 'No name'}');
                                },
                              );
                            },
                          ),
                        ),
                        DataCell(Text('$winCount')),
                      ],
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
