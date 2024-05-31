import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/matches/match_details_screen.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';

class PoolsTab extends StatelessWidget {
  final String tournamentId;
  final TournamentService tournamentService;

  PoolsTab({
    required this.tournamentId,
    required this.tournamentService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: tournamentService.getPoolsStream(tournamentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var pools = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: pools.length,
          itemBuilder: (context, index) {
            var poolData = pools[index].data() as Map<String, dynamic>;
            List<Map<String, dynamic>> matchesInPool = List<Map<String, dynamic>>.from(poolData['matches'] ?? []);

            return ExpansionTile(
              title: Text('Pool ${index + 1} Matches:'),
              children: matchesInPool.map((match) {
                return ListTile(
                  title: Text(
                    'Teams: ${match['team1']['ukbtno1']} & ${match['team1']['ukbtno2']} vs ${match['team2']['ukbtno1']} & ${match['team2']['ukbtno2']}',
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Time: ${DateTime.parse(match['time']).hour}:00'),
                      Text('Status: ${match['status']}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchDetailsScreen(
                          tournamentId: tournamentId,
                          poolId: pools[index].id,
                          matchIndex: matchesInPool.indexOf(match),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
