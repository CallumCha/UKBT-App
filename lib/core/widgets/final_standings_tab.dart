import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinalStandingsTab extends StatelessWidget {
  final String tournamentId;

  const FinalStandingsTab({Key? key, required this.tournamentId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchFinalStandings() async {
    final docSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
    final data = docSnapshot.data();

    if (data != null && data['final_standings'] != null) {
      List<Map<String, dynamic>> standings = List<Map<String, dynamic>>.from(data['final_standings']);
      standings.sort((a, b) => a['position'].compareTo(b['position']));
      return standings;
    }

    return [];
  }

  Future<Map<String, String>> _fetchTeamPlayerNames(String teamId) async {
    final teamSnapshot = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).collection('teams').doc(teamId).get();
    if (teamSnapshot.exists) {
      final teamData = teamSnapshot.data() as Map<String, dynamic>;
      final player1Id = teamData['player1'];
      final player2Id = teamData['player2'];

      final player1Name = await _fetchUserName(player1Id);
      final player2Name = await _fetchUserName(player2Id);

      return {
        'player1Name': player1Name,
        'player2Name': player2Name,
      };
    }
    return {
      'player1Name': 'No data',
      'player2Name': 'No data',
    };
  }

  Future<String> _fetchUserName(String userId) async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      return userData['name'] ?? 'No name';
    }
    return 'No name';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchFinalStandings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No final standings available'));
        }

        final standings = snapshot.data!;

        return ListView(
          children: [
            DataTable(
              columns: const [
                DataColumn(label: Text('Position')),
                DataColumn(label: Text('Player 1')),
                DataColumn(label: Text('Player 2')),
              ],
              rows: standings.map((entry) {
                final teamId = entry['team'] as String?;
                if (teamId == null) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${entry['position']}')),
                      const DataCell(Text('No data')),
                      const DataCell(Text('No data')),
                    ],
                  );
                }

                return DataRow(
                  cells: [
                    DataCell(Text('${entry['position']}')),
                    DataCell(
                      FutureBuilder<Map<String, String>>(
                        future: _fetchTeamPlayerNames(teamId),
                        builder: (context, teamSnapshot) {
                          if (teamSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Loading...');
                          }
                          if (!teamSnapshot.hasData) {
                            return const Text('No data');
                          }
                          final playerNames = teamSnapshot.data!;
                          return Text(playerNames['player1Name']!);
                        },
                      ),
                    ),
                    DataCell(
                      FutureBuilder<Map<String, String>>(
                        future: _fetchTeamPlayerNames(teamId),
                        builder: (context, teamSnapshot) {
                          if (teamSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Loading...');
                          }
                          if (!teamSnapshot.hasData) {
                            return const Text('No data');
                          }
                          final playerNames = teamSnapshot.data!;
                          return Text(playerNames['player2Name']!);
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
