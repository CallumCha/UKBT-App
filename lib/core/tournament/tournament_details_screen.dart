import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/matches/matches_tab.dart';
import 'package:ukbtapp/core/tournament/tournament_service.dart';
import 'package:ukbtapp/core/tournament/tournament_model.dart';
import 'package:ukbtapp/core/tournament/teams_tab.dart';
import 'package:ukbtapp/core/tournament/pools_tab.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;

  TournamentDetailsScreen({required this.tournamentId});

  @override
  _TournamentDetailsScreenState createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final TextEditingController _ukbtno1Controller = TextEditingController();
  final TextEditingController _ukbtno2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePools();
    });
  }

  Future<void> _registerTeam() async {
    // Register team logic...
  }

  Future<void> _updatePools() async {
    // Update pools logic...
  }

  @override
  Widget build(BuildContext context) {
    final tournamentService = Provider.of<TournamentService>(context);
    final tournamentId = widget.tournamentId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tournament Details'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Teams'),
              Tab(text: 'Pools'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: tournamentService.getTournamentStream(tournamentId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var tournamentData = snapshot.data!.data() as Map<String, dynamic>;
            Tournament tournament = Tournament.fromFirestore(snapshot.data!);

            return TabBarView(
              children: [
                TeamsTab(tournament: tournament),
                PoolsTab(tournamentId: tournamentId, tournamentService: tournamentService),
                MatchesTab(tournamentId: tournamentId, tournamentService: tournamentService),
              ],
            );
          },
        ),
      ),
    );
  }
}
