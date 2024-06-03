import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/core/auth/models/user_model.dart';
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/auth/models/team_model.dart';

class RegistrationPage extends StatefulWidget {
  final Tournament tournament;

  RegistrationPage({required this.tournament});

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
    _tabController = TabController(length: 3, vsync: this);
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
    final snapshot = await FirebaseFirestore.instance.collection('teams').where('tournamentId', isEqualTo: widget.tournament.id).get();
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
      'registrationOpen': false
    });
    setState(() {
      widget.tournament.registrationOpen = false;
    });
    _createPoolsAndKnockouts();
  }

  Future<void> _createPoolsAndKnockouts() async {
    int poolSize = 4; // Adjust pool size as necessary
    int numPools = (registeredTeams.length / poolSize).ceil();
    List<List<Team>> pools = List.generate(numPools, (_) => []);

    // Distribute teams into pools
    for (int i = 0; i < registeredTeams.length; i++) {
      pools[i % numPools].add(registeredTeams[i]);
    }

    // Create pools in Firestore
    for (int i = 0; i < pools.length; i++) {
      await FirebaseFirestore.instance.collection('pools').add({
        'tournamentId': widget.tournament.id,
        'name': 'Pool ${String.fromCharCode(65 + i)}', // Pool A, Pool B, etc.
        'teams': pools[i].map((team) => team.id).toList(),
      });
    }

    // Create knockout matches with placeholders
    for (int i = 0; i < numPools; i++) {
      for (int j = i + 1; j < numPools; j++) {
        await FirebaseFirestore.instance.collection('matches').add({
          'tournamentId': widget.tournament.id,
          'stage': 'knockout',
          'round': 1,
          'team1': 'Winner Pool ${String.fromCharCode(65 + i)}',
          'team2': 'Second Pool ${String.fromCharCode(65 + j)}',
          'score1': 0,
          'score2': 0,
          'completed': false,
        });
      }
    }
  }

  void _registerTeam(String user1UkbtNo, String user2UkbtNo) async {
    final user1Uid = await _getUserUidByUkbtNo(user1UkbtNo);
    final user2Uid = await _getUserUidByUkbtNo(user2UkbtNo);
    if (user1Uid != null && user2Uid != null) {
      await FirebaseFirestore.instance.collection('teams').add({
        'tournamentId': widget.tournament.id,
        'user1': user1Uid,
        'user2': user2Uid,
        'name': 'Team ${user1UkbtNo.substring(0, 4)} & ${user2UkbtNo.substring(0, 4)}',
      });
      _fetchRegisteredTeams();
    } else {
      // Handle case where user UIDs are not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for ${widget.tournament.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Registration'),
            Tab(text: 'Pools'),
            Tab(text: 'Playoffs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegistrationTab(),
          _buildPoolsTab(),
          _buildPlayoffsTab(),
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
                decoration: InputDecoration(labelText: 'Enter UKBT No for Player 1'),
              ),
              TextField(
                controller: user2Controller,
                decoration: InputDecoration(labelText: 'Enter UKBT No for Player 2'),
              ),
              ElevatedButton(
                onPressed: () {
                  _registerTeam(user1Controller.text, user2Controller.text);
                },
                child: Text('Register'),
              ),
            ],
          )
        else
          Text('Registration is closed'),
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
                    DataCell(FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(team.user1).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Loading...');
                        } else if (!snapshot.hasData || snapshot.data?.data() == null) {
                          return Text('No data');
                        } else {
                          return Text((snapshot.data!.data() as Map<String, dynamic>)['name']);
                        }
                      },
                    )),
                    DataCell(FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(team.user2).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Loading...');
                        } else if (!snapshot.hasData || snapshot.data?.data() == null) {
                          return Text('No data');
                        } else {
                          return Text((snapshot.data!.data() as Map<String, dynamic>)['name']);
                        }
                      },
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (isAdmin && widget.tournament.registrationOpen)
          ElevatedButton(
            onPressed: _closeRegistration,
            child: Text('Close Registration'),
          ),
      ],
    );
  }

  Widget _buildPoolsTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('pools').where('tournamentId', isEqualTo: widget.tournament.id).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No pools available'));
        }
        final pools = snapshot.data!.docs;
        return ListView.builder(
          itemCount: pools.length,
          itemBuilder: (context, index) {
            final pool = pools[index];
            final poolName = pool['name'];
            final teamIds = List<String>.from(pool['teams']);
            return ExpansionTile(
              title: Text(poolName),
              children: teamIds.map((teamId) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('teams').doc(teamId).get(),
                  builder: (context, teamSnapshot) {
                    if (teamSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(title: Text('Loading...'));
                    }
                    final teamData = teamSnapshot.data?.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(teamData['name']),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayoffsTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('matches').where('tournamentId', isEqualTo: widget.tournament.id).where('stage', isEqualTo: 'knockout').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No matches available'));
        }
        final matches = snapshot.data!.docs;
        Map<int, List<DocumentSnapshot>> rounds = {};
        for (var match in matches) {
          int round = match['round'];
          if (rounds.containsKey(round)) {
            rounds[round]!.add(match);
          } else {
            rounds[round] = [
              match
            ];
          }
        }
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rounds.keys.map((round) {
                return ChoiceChip(
                  label: Text(round == 1
                      ? 'QF'
                      : round == 2
                          ? 'SF'
                          : 'Final'),
                  selected: _tabController?.index == round,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _tabController?.index = round;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rounds[_tabController?.index]?.length ?? 0,
                itemBuilder: (context, index) {
                  final match = rounds[_tabController?.index]?[index];
                  return ListTile(
                    title: Text('${match?['team1']} vs ${match?['team2']}'),
                    subtitle: Text('Score: ${match?['score1']} - ${match?['score2']}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
