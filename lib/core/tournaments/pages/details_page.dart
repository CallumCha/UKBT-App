import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/core/tournaments/models/team_model.dart';
import 'package:ukbtapp/core/tournaments/models/pool_model.dart';
import 'package:ukbtapp/core/tournaments/pool_generator.dart';
import '../widgets/registration_form.dart'; // Updated import

class DetailsPage extends StatefulWidget {
  final String tournamentId;

  const DetailsPage({super.key, required this.tournamentId}); // Use super parameter

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String _ukbtno1 = '';
  String _ukbtno2 = '';
  bool _isAdmin = false;
  bool _registrationOpen = true;
  Map<String, dynamic>? _tournamentData;
  List<Team> _teams = [];
  List<Pool> _pools = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchTournamentDetails();
  }

  Future<void> _checkAdminStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = await authService.isAdmin();
    final user = FirebaseAuth.instance.currentUser;

    if (isAdmin && user != null) {
      setState(() {
        _isAdmin = true;
        _ukbtno1 = ''; // Fetch the user's UKBT number from Firestore if needed
      });
    }
  }

  Future<void> _fetchTournamentDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
      if (doc.exists) {
        final tournamentData = doc.data();
        if (tournamentData != null) {
          print("Tournament Data: $tournamentData"); // Replace with logging framework

          final teams = (tournamentData['teams'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          final teamDetails = await _fetchTeamDetails(teams);

          final poolsList = (tournamentData['pools'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          final pools = poolsList.map((poolData) => Pool.fromMap(poolData)).toList();

          setState(() {
            _tournamentData = tournamentData;
            _registrationOpen = tournamentData['registrationOpen'] ?? true;
            _teams = teamDetails;
            _pools = pools;
          });
        }
      }
    } catch (e) {
      print(e); // Replace with logging framework
    }
  }

  Future<List<Team>> _fetchTeamDetails(List<Map<String, dynamic>> teams) async {
    List<Team> teamDetails = [];
    for (var team in teams) {
      final String ukbtno1 = team['ukbtno1'].toString();
      final String ukbtno2 = team['ukbtno2'].toString();

      final user1Query = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtno1).get();
      final user2Query = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtno2).get();

      final user1Doc = user1Query.docs.isNotEmpty ? user1Query.docs.first : null;
      final user2Doc = user2Query.docs.isNotEmpty ? user2Query.docs.first : null;

      final user1Data = user1Doc?.data();
      final user2Data = user2Doc?.data();

      final user1Name = user1Data?['name'] ?? 'Unknown';
      final user2Name = user2Data?['name'] ?? 'Unknown';

      teamDetails.add(Team(
        ukbtno1: ukbtno1,
        ukbtno2: ukbtno2,
        user1Name: user1Name,
        user2Name: user2Name,
        elo1: user1Data?['elo']?.toString() ?? '0',
        elo2: user2Data?['elo']?.toString() ?? '0',
      ));
    }
    return teamDetails;
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
      final docSnapshot = await tournamentDoc.get();
      final currentTeams = (docSnapshot.data()?['teams'] ?? []).length;

      if (currentTeams >= 16) {
        setState(() {
          _registrationOpen = false;
        });
        return;
      }

      final data = {
        'ukbtno1': _ukbtno1,
        'ukbtno2': _ukbtno2,
      };

      await tournamentDoc.update({
        'teams': FieldValue.arrayUnion([
          data
        ])
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        actions: _isAdmin
            ? [
                Switch(
                  value: _registrationOpen,
                  onChanged: (value) async {
                    await _toggleRegistration();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTeams,
                ),
              ]
            : null,
      ),
      body: _tournamentData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${_tournamentData?['name']}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('Date: ${_tournamentData?['date']}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('Level: ${_tournamentData?['level']}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('Location: ${_tournamentData?['location']}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('Gender: ${_tournamentData?['gender']}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    const Text('Teams Registered:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _teams.isEmpty
                        ? const Center(child: Text('No teams registered yet'))
                        : Table(
                            border: TableBorder.all(),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(3),
                            },
                            children: [
                              const TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Player 1', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Player 2', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ]),
                              ..._teams.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final team = entry.value;
                                return TableRow(children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('$index'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(team.user1Name),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(team.user2Name),
                                  ),
                                ]);
                              }),
                            ],
                          ),
                    if (_registrationOpen) RegistrationForm(formKey: _formKey, isAdmin: _isAdmin, ukbtno1: _ukbtno1, onSavedUkbtno1: (value) => _ukbtno1 = value!, onSavedUkbtno2: (value) => _ukbtno2 = value!), // Update with correct method
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _toggleRegistration() async {
    setState(() {
      _registrationOpen = !_registrationOpen;
    });
    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
    await tournamentDoc.update({
      'registrationOpen': _registrationOpen
    });
  }

  void _addTeams() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Teams'),
        content: RegistrationForm(formKey: _formKey, isAdmin: _isAdmin, ukbtno1: _ukbtno1, onSavedUkbtno1: (value) => _ukbtno1 = value!, onSavedUkbtno2: (value) => _ukbtno2 = value!), // Update with correct method
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _submitRegistration();
              Navigator.of(context).pop();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
