import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/registration_page.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  _TournamentScreenState createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  List<Tournament> tournaments = [];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTournaments();
  }

  Future<void> _fetchUserData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = doc.data()?['admin'] ?? false;
      });
    }
  }

  Future<void> _fetchTournaments() async {
    final snapshot = await FirebaseFirestore.instance.collection('tournaments').get();
    setState(() {
      tournaments = snapshot.docs.map((doc) => Tournament.fromDocument(doc)).toList();
    });
  }

  void _showCreateTournamentDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController genderController = TextEditingController();
    final TextEditingController levelController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Tournament'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: genderController,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a gender';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: levelController,
                    decoration: const InputDecoration(labelText: 'Level'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a level';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _createTournament(
                    nameController.text,
                    genderController.text,
                    levelController.text,
                    locationController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createTournament(String name, String gender, String level, String location) async {
    await FirebaseFirestore.instance.collection('tournaments').add({
      'name': name,
      'stage': 'registration',
      'registrationOpen': true,
      'gender': gender,
      'level': level,
      'location': location,
    });
    _fetchTournaments(); // Refresh the list of tournaments
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
      ),
      body: Column(
        children: [
          if (isAdmin)
            ElevatedButton(
              onPressed: _showCreateTournamentDialog,
              child: const Text('Create Tournament'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return ListTile(
                  title: Text(tournament.name),
                  subtitle: Text('Stage: ${tournament.stage}'),
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
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
