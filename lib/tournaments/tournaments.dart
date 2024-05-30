import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/tournaments/tournament_details.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading tournaments'));
          }

          final tournaments = snapshot.data?.docs ?? [];

          if (tournaments.isEmpty) {
            return const Center(child: Text('No tournaments available'));
          }

          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              final data = tournament.data() as Map<String, dynamic>;

              // Safely convert teams and reserves to List<Map<String, dynamic>>
              final teams = (data['teams'] as List<dynamic>? ?? []).map((team) => Map<String, dynamic>.from(team as Map)).toList();
              final reserves = (data['reserve'] as List<dynamic>? ?? []).map((reserve) => Map<String, dynamic>.from(reserve as Map)).toList();

              return TournamentTile(
                tournamentId: tournament.id,
                date: data['date'] ?? '',
                location: data['location'] ?? '',
                level: data['level'] ?? '',
                gender: data['gender'] ?? '',
                teams: teams,
                reserves: reserves,
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(x: 2),
    );
  }
}

class TournamentTile extends StatelessWidget {
  final String tournamentId;
  final String date;
  final String location;
  final String level;
  final String gender;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> reserves;

  const TournamentTile({
    super.key,
    required this.tournamentId,
    required this.date,
    required this.location,
    required this.level,
    required this.gender,
    required this.teams,
    required this.reserves,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$location $level $gender',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text('Date: $date'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentDetailsScreen(
                      tournamentId: tournamentId,
                      location: location,
                      level: level,
                      gender: gender,
                      date: date,
                      teams: teams,
                      reserves: reserves,
                    ),
                  ),
                );
              },
              child: const Text('Info'),
            ),
          ],
        ),
      ),
    );
  }
}
