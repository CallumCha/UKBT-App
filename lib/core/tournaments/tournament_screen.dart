import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'tournament_detail_screen.dart'; // Import the new screen

// Main Tournament Screen
class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTournamentScreen()),
              );
            },
          ),
        ],
      ),
      body: const TournamentList(), // Display list of tournaments
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
}

// Section for displaying the list of tournaments
class TournamentList extends StatelessWidget {
  const TournamentList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              title: Text(doc['name']),
              subtitle: Text(doc['date']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentDetailScreen(tournamentId: doc.id),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

// Section for adding a new tournament
class AddTournamentScreen extends StatefulWidget {
  const AddTournamentScreen({super.key});

  @override
  _AddTournamentScreenState createState() => _AddTournamentScreenState();
}

class _AddTournamentScreenState extends State<AddTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  String _title = '';
  String _level = '1*';
  String _location = '';
  String _gender = 'Male';

  final List<String> _levels = [
    '1*',
    '2*',
    '3*',
    '4*',
    'Open'
  ];
  final List<String> _genders = [
    'Male',
    'Female',
    'Mixed'
  ];

  // Logic for submitting the form and creating a new tournament
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final tournamentId = FirebaseFirestore.instance.collection('tournaments').doc().id;

      final data = {
        'tournamentUId': tournamentId,
        'date': _dateController.text,
        'name': _title,
        'level': _level,
        'location': _location,
        'gender': _gender,
        'pools': [],
        'registrationOpen': true, // Add registration open field
        'teams': [], // Initialize an empty list for teams
      };

      await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).set(data);

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tournament'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // UI for inputting the tournament date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (dd-mm-yyyy)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  return null;
                },
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                    });
                  }
                },
              ),
              // UI for inputting the tournament title
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value ?? '';
                },
              ),
              // UI for selecting the tournament level
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Level'),
                value: _level,
                items: _levels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _level = value ?? '1*';
                  });
                },
                onSaved: (value) {
                  _level = value ?? '1*';
                },
              ),
              // UI for inputting the tournament location
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
                onSaved: (value) {
                  _location = value ?? '';
                },
              ),
              // UI for selecting the tournament gender
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: _gender,
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value ?? 'Male';
                  });
                },
                onSaved: (value) {
                  _gender = value ?? 'Male';
                },
              ),
              const SizedBox(height: 20),
              // UI for saving the tournament
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Tournament'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
