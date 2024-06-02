import 'package:flutter/material.dart';
import 'pages/details_page.dart';
import 'pages/pools_page.dart';
import 'pages/matches_page.dart';
import 'pages/knockout_page.dart';

class TournamentDetailScreen extends StatelessWidget {
  final String tournamentId;

  const TournamentDetailScreen({Key? key, required this.tournamentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Pools'),
              Tab(text: 'Matches'),
              Tab(text: 'Knockout'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DetailsPage(tournamentId: tournamentId),
            PoolsPage(tournamentId: tournamentId),
            MatchesPage(tournamentId: tournamentId),
            KnockoutPage(tournamentId: tournamentId),
          ],
        ),
      ),
    );
  }
}
