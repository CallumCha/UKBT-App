import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/core/auth/models/user_model.dart';
import 'package:ukbtapp/core/widgets/update_all_users_tournament_history.dart';
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/registration_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tournament> _upcomingTournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTournaments();
  }

  Future<void> _fetchUpcomingTournaments() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.data()!.containsKey('registeredTournaments')) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'registeredTournaments': [],
        });
      }

      final registeredTournamentIds = List<String>.from(userDoc.data()!['registeredTournaments'] ?? []);

      setState(() {
        _upcomingTournaments = []; // Initialize with an empty list
      });

      if (registeredTournamentIds.isNotEmpty) {
        final now = DateTime.now();
        for (String tournamentId in registeredTournamentIds) {
          final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();

          if (tournamentDoc.exists) {
            final tournamentData = tournamentDoc.data()!;
            final tournamentDate = tournamentData['date'] as Timestamp;
            if (tournamentDate.toDate().isAfter(now)) {
              setState(() {
                _upcomingTournaments.add(Tournament.fromMap(tournamentData, tournamentId));
              });
              if (_upcomingTournaments.length >= 2) break; // Limit to 2 tournaments
            }
          }
        }
      }
    }
  }

  void _updateTournamentHistory(BuildContext context) async {
    try {
      await updateAllUsersTournamentHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament history updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating tournament history: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Upcoming Tournaments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (_upcomingTournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You have no upcoming tournaments'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _upcomingTournaments.length,
                itemBuilder: (context, index) {
                  final tournament = _upcomingTournaments[index];
                  return ListTile(
                    title: Text(tournament.name),
                    subtitle: Text(
                      '${tournament.gender} - ${tournament.level}\n'
                      '${tournament.location}',
                    ),
                    trailing: Text(
                      tournament.date?.toLocal().toString().split(' ')[0] ?? 'Date not specified',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationPage(tournament: tournament),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _updateTournamentHistory(context),
                child: const Text('Update Tournament History'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/tournaments');
          }
        },
      ),
    );
  }
}
