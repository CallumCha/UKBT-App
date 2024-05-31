import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';
import 'package:ukbtapp/core/matches/match_details_screen.dart';
import 'package:ukbtapp/core/matches/components/match_list_tile.dart';

class MatchesTab extends StatelessWidget {
  final String tournamentId;
  final TournamentService tournamentService;

  MatchesTab({
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
                return MatchListTile(
                  tournamentId: tournamentId,
                  poolId: pools[index].id,
                  matchIndex: matchesInPool.indexOf(match),
                  match: match,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
