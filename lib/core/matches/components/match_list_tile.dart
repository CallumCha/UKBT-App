import 'package:flutter/material.dart';
import 'package:ukbtapp/core/matches/match_details_screen.dart';

class MatchListTile extends StatelessWidget {
  final String tournamentId;
  final String poolId;
  final int matchIndex;
  final Map<String, dynamic> match;

  const MatchListTile({
    Key? key,
    required this.tournamentId,
    required this.poolId,
    required this.matchIndex,
    required this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var team1 = match['team1'];
    var team2 = match['team2'];
    bool isMatchPlayed = match['status'] == 'played';

    return ListTile(
      title: Text(
        'Teams: ${team1['ukbtno1']} & ${team1['ukbtno2']} vs ${team2['ukbtno1']} & ${team2['ukbtno2']}',
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Time: ${DateTime.parse(match['time']).hour}:00'),
          Text('Status: ${match['status']}'),
        ],
      ),
      onTap: () {
        if (!isMatchPlayed) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailsScreen(
                tournamentId: tournamentId,
                poolId: poolId,
                matchIndex: matchIndex,
              ),
            ),
          );
        }
      },
    );
  }
}
