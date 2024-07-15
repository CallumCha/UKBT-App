import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/auth/models/team_model.dart';
import 'package:ukbtapp/core/widgets/pools_tab.dart'; // Import the PoolsTab widget
import 'package:ukbtapp/core/widgets/matches_tab.dart'; // Import the MatchesTab widget
import 'package:ukbtapp/core/widgets/knockout_matches_tab.dart'; // Import the KnockoutMatchesTab widget
import 'package:ukbtapp/core/widgets/final_standings_tab.dart'; // Import the FinalStandingsTab widget

class RegistrationPage extends StatefulWidget {
  final Tournament tournament;

  const RegistrationPage({super.key, required this.tournament});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  bool isAdmin = false;
  List<Team> registeredTeams = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchRegisteredTeams();
    _tabController = TabController(length: 5, vsync: this); // Set the length to 5 for the five tabs
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

  Future<void> _fetchRegisteredTeams() async {
    final snapshot = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('teams').get();
    List<Team> teams = [];
    for (var teamDoc in snapshot.docs) {
      teams.add(Team.fromDocument(teamDoc));
    }
    setState(() {
      registeredTeams = teams;
    });
  }

  Future<String?> _getUserUidByUkbtNo(String ukbtNo) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtNo).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  void _closeRegistration() async {
    await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).update({
      'registrationOpen': false,
    });
    setState(() {
      widget.tournament.registrationOpen = false;
    });

    // Assign teams to pools
    int poolSize = 4; // Adjust pool size as necessary
    int numPools = (registeredTeams.length / poolSize).ceil();
    List<List<Team>> pools = List.generate(numPools, (_) => []);

    // Distribute teams into pools
    for (int i = 0; i < registeredTeams.length; i++) {
      pools[i % numPools].add(registeredTeams[i]);
    }

    // Create pools and matches in Firestore
    for (int i = 0; i < pools.length; i++) {
      String poolName = 'Pool ${String.fromCharCode(65 + i)}'; // Pool A, Pool B, etc.
      DocumentReference poolDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('pools').doc(poolName);

      await poolDoc.set({
        'teams': pools[i].map((team) => team.id).toList(),
        'wins': pools[i].map((team) => 0).toList(), // Initialize wins to 0
      });

      // Create matches for each pool
      for (int j = 0; j < pools[i].length; j++) {
        for (int k = j + 1; k < pools[i].length; k++) {
          await poolDoc.collection('pool_matches').add({
            'team1': pools[i][j].id,
            'team2': pools[i][k].id,
            'winner': '',
            'type': poolName,
          });
        }
      }
    }
  }

  void _registerTeam(String user1UkbtNo, String user2UkbtNo) async {
    final user1Uid = await _getUserUidByUkbtNo(user1UkbtNo);
    final user2Uid = await _getUserUidByUkbtNo(user2UkbtNo);
    if (user1Uid != null && user2Uid != null) {
      await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id).collection('teams').add({
        'player1': user1Uid,
        'player2': user2Uid,
        'ukbtno1': user1UkbtNo,
        'ukbtno2': user2UkbtNo,
      });
      _fetchRegisteredTeams();
    } else {
      // Handle case where user UIDs are not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User(s) not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for ${widget.tournament.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Registration'),
            Tab(text: 'Pools'),
            Tab(text: 'Matches'),
            Tab(text: 'Knockout Matches'), // Add the Knockout Matches tab here
            Tab(text: 'Final Standings'), // Add the Final Standings tab here
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegistrationTab(),
          PoolsTab(tournamentId: widget.tournament.id),
          MatchesTab(tournamentId: widget.tournament.id),
          KnockoutMatchesTab(tournamentId: widget.tournament.id), // Use the KnockoutMatchesTab widget
          FinalStandingsTab(tournamentId: widget.tournament.id), // Use the FinalStandingsTab widget
        ],
      ),
    );
  }

  Widget _buildRegistrationTab() {
    final TextEditingController user1Controller = TextEditingController();
    final TextEditingController user2Controller = TextEditingController();

    return Column(
      children: [
        if (widget.tournament.registrationOpen)
          Column(
            children: [
              TextField(
                controller: user1Controller,
                decoration: const InputDecoration(labelText: 'Enter UKBT No for Player 1'),
              ),
              TextField(
                controller: user2Controller,
                decoration: const InputDecoration(labelText: 'Enter UKBT No for Player 2'),
              ),
              ElevatedButton(
                onPressed: () {
                  _registerTeam(user1Controller.text, user2Controller.text);
                },
                child: const Text('Register'),
              ),
            ],
          )
        else
          const Text('Registration is closed'),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Player 1')),
                DataColumn(label: Text('Player 2')),
              ],
              rows: registeredTeams.asMap().entries.map((entry) {
                int index = entry.key + 1;
                Team team = entry.value;
                return DataRow(
                  cells: [
                    DataCell(Text('$index')),
                    DataCell(
                      team.user1.isNotEmpty
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(team.user1).get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Loading...');
                                } else if (!snapshot.hasData || snapshot.data?.data() == null) {
                                  return const Text('No data');
                                } else {
                                  return Text((snapshot.data!.data() as Map<String, dynamic>)['name']);
                                }
                              },
                            )
                          : const Text('No data'),
                    ),
                    DataCell(
                      team.user2.isNotEmpty
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(team.user2).get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Loading...');
                                } else if (!snapshot.hasData || snapshot.data?.data() == null) {
                                  return const Text('No data b');
                                } else {
                                  return Text((snapshot.data!.data() as Map<String, dynamic>)['name']);
                                }
                              },
                            )
                          : const Text('No data c'),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (isAdmin && widget.tournament.registrationOpen)
          ElevatedButton(
            onPressed: _closeRegistration,
            child: const Text('Close Registration'),
          ),
      ],
    );
  }
}
