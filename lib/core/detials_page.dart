import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/core/auth/models/team_model.dart' as team_model;
import 'package:ukbtapp/core/auth/models/tournament_model.dart' as tournament_model;

class DetailsPage extends StatefulWidget {
  final String tournamentId;

  const DetailsPage({super.key, required this.tournamentId});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  tournament_model.Tournament? _tournament;
  List<team_model.Team> _teams = [];

  @override
  void initState() {
    super.initState();
    _fetchTournamentDetails();
    _fetchTeams();
  }

  Future<void> _fetchTournamentDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();

    setState(() {
      _tournament = tournament_model.Tournament.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> _fetchTeams() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('teams').where('tournamentId', isEqualTo: widget.tournamentId).get();

    setState(() {
      _teams = snapshot.docs.map((doc) => team_model.Team.fromDocument(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament?.name ?? 'Tournament Details'),
      ),
      body: _tournament == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  title: const Text('Tournament ID'),
                  subtitle: Text(_tournament?.id ?? ''),
                ),
                ListTile(
                  title: const Text('Name'),
                  subtitle: Text(_tournament?.name ?? ''),
                ),
                ListTile(
                  title: const Text('Gender'),
                  subtitle: Text(_tournament?.gender ?? ''),
                ),
                ListTile(
                  title: const Text('Level'),
                  subtitle: Text(_tournament?.level ?? ''),
                ),
                ListTile(
                  title: const Text('Location'),
                  subtitle: Text(_tournament?.location ?? ''),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      return ListTile(
                        title: Text(team.id),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
