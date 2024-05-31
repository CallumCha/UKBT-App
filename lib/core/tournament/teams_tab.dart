import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';
import 'package:ukbtapp/core/tournament/tournament_model.dart';

class TeamsTab extends StatelessWidget {
  final Tournament tournament;

  TeamsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tournament.teams.length,
      itemBuilder: (context, index) {
        var team = tournament.teams[index];
        return ListTile(
          title: Text('Team ${index + 1}'),
          subtitle: Text('UKBTNo1: ${team['ukbtno1']} - UKBTNo2: ${team['ukbtno2']}'),
        );
      },
    );
  }
}
