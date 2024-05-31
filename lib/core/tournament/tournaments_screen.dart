import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/tournament/tournament_model.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';
import 'package:ukbtapp/core/tournament/tournament_details_screen.dart';

class TournamentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tournamentService = Provider.of<TournamentService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tournaments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tournamentService.getTournamentsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var tournaments = snapshot.data!.docs.map((doc) => Tournament.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              var tournament = tournaments[index];
              var tournamentDoc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(tournament.name),
                subtitle: Text(tournament.location),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentDetailsScreen(tournamentId: tournamentDoc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
