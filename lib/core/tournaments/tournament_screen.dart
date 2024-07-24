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
  String _selectedFilter = 'upcoming';

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
    final now = DateTime.now();
    setState(() {
      tournaments = snapshot.docs.map((doc) => Tournament.fromDocument(doc)).toList();
      tournaments = tournaments.where((tournament) {
        if (_selectedFilter == 'upcoming') {
          return tournament.date != null && tournament.date!.isAfter(now);
        } else {
          return tournament.date == null || tournament.date!.isBefore(now);
        }
      }).toList();
      tournaments.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return _selectedFilter == 'upcoming' ? a.date!.compareTo(b.date!) : b.date!.compareTo(a.date!);
      });
    });
  }

  void _showCreateTournamentDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController genderController = TextEditingController();
    final TextEditingController levelController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Tournament'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && picked != selectedDate) {
                        selectedDate = picked;
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                      ),
                      child: Text(
                        "${selectedDate.toLocal()}".split(' ')[0],
                      ),
                    ),
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
                    selectedDate,
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

  void _createTournament(String name, String gender, String level, String location, DateTime date) async {
    await FirebaseFirestore.instance.collection('tournaments').add({
      'name': name,
      'stage': 'registration',
      'registrationOpen': true,
      'gender': gender,
      'level': level,
      'location': location,
      'date': Timestamp.fromDate(date),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Upcoming'),
                  selected: _selectedFilter == 'upcoming',
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = 'upcoming';
                      _fetchTournaments();
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Past'),
                  selected: _selectedFilter == 'past',
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = 'past';
                      _fetchTournaments();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return ListTile(
                  title: Text(tournament.name),
                  subtitle: Text(
                    '${tournament.gender} - ${tournament.level} - ${tournament.location}\n'
                    'Date: ${tournament.date?.toLocal().toString().split(' ')[0] ?? 'Not specified'}',
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
