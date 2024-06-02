import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/core/tournaments/models/team_model.dart';
import 'package:ukbtapp/core/tournaments/models/pool_model.dart';
import 'package:ukbtapp/core/tournaments/pool_generator.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  _TournamentDetailScreenState createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
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
          print("Tournament Data: $tournamentData");

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
      print(e);
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Pools'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(),
            _buildPoolsTab(),
            _buildMatchesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return _tournamentData == null
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
                  if (_registrationOpen) _buildRegistrationForm(),
                ],
              ),
            ),
          );
  }

  Widget _buildRegistrationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _isAdmin ? _ukbtno1 : null,
              decoration: const InputDecoration(labelText: 'UKBT Number 1'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid UKBT Number';
                }
                return null;
              },
              onSaved: (value) {
                _ukbtno1 = value ?? '';
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: 'UKBT Number 2'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid UKBT Number';
                }
                return null;
              },
              onSaved: (value) {
                _ukbtno2 = value ?? '';
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRegistration,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching pools'));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: Text('No pools data available'));
        }

        final tournamentData = snapshot.data!.data() as Map<String, dynamic>;
        final poolsList = (tournamentData['pools'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        final pools = poolsList.map((poolData) => Pool.fromMap(poolData)).toList();

        return ListView.builder(
          itemCount: pools.length,
          itemBuilder: (context, index) {
            final pool = pools[index];
            final standings = pool.standings ?? [];
            standings.sort((a, b) {
              final int winsA = a['w'] as int;
              final int winsB = b['w'] as int;
              if (winsA != winsB) {
                return winsB.compareTo(winsA);
              }
              final int setsDiffA = (a['sWon'] as int) - (a['sLost'] as int);
              final int setsDiffB = (b['sWon'] as int) - (b['sLost'] as int);
              return setsDiffB.compareTo(setsDiffA);
            });
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pool.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('MP', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...standings.map<TableRow>((standing) {
                          final team = standing['team'];
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team['user1Name'] ?? 'Unknown'),
                                    Text(team['user2Name'] ?? 'Unknown'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(standing['mp'].toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(standing['w'].toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(standing['l'].toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${standing['sWon']}:${standing['sLost']}'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching matches'));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: Text('No matches data available'));
        }

        final tournamentData = snapshot.data!.data() as Map<String, dynamic>;
        final poolsList = (tournamentData['pools'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        final pools = poolsList.map((poolData) => Pool.fromMap(poolData)).toList();

        return ListView.builder(
          itemCount: pools.length,
          itemBuilder: (context, poolIndex) {
            final pool = pools[poolIndex];
            final matches = pool.matches ?? [];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pool.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...matches.asMap().entries.map((entry) {
                      final matchIndex = entry.key;
                      final match = entry.value;
                      final result = match['result'];
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${match['team1']['user1Name']} & ${match['team1']['user2Name']}'),
                            Text('${match['team2']['user1Name']} & ${match['team2']['user2Name']}'),
                          ],
                        ),
                        trailing: result == null
                            ? ElevatedButton(
                                onPressed: () => _showScoreInputPopup(context, poolIndex, matchIndex, match),
                                child: const Text('Input Score'),
                              )
                            : Text('${result['setsTeam1']} - ${result['setsTeam2']}'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleRegistration() async {
    try {
      final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
      final docSnapshot = await tournamentDoc.get();
      final data = docSnapshot.data();

      if (data != null) {
        if (_registrationOpen) {
          await _generatePools();
        }

        await tournamentDoc.update({
          'registrationOpen': !_registrationOpen
        });
        setState(() {
          _registrationOpen = !_registrationOpen;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _generatePools() async {
    final poolGenerator = PoolGenerator();
    final pools = poolGenerator.createPools(_teams);

    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
    await tournamentDoc.update({
      'pools': pools.map((pool) => pool.toMap()).toList(),
    });

    setState(() {
      _pools = pools;
    });
  }

  void _addTeams() {
    final teams = [
      {
        'ukbtno1': '9819',
        'ukbtno2': '2536'
      },
      {
        'ukbtno1': '3440',
        'ukbtno2': '4461'
      },
      {
        'ukbtno1': '5697',
        'ukbtno2': '9673'
      },
      {
        'ukbtno1': '4483',
        'ukbtno2': '7186'
      },
      {
        'ukbtno1': '9721',
        'ukbtno2': '7182'
      },
    ];

    FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
      'teams': FieldValue.arrayUnion(teams),
    }).then((_) {
      _fetchTournamentDetails(); // Refresh the tournament details after adding teams
    });
  }

  void _showScoreInputPopup(BuildContext context, int poolIndex, int matchIndex, Map<String, dynamic> match) {
    final team1 = match['team1'];
    final team2 = match['team2'];
    final TextEditingController team1SetsController = TextEditingController();
    final TextEditingController team2SetsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter Match Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('${team1['user1Name']} & ${team1['user2Name']} vs ${team2['user1Name']} & ${team2['user2Name']}'),
              const SizedBox(height: 10),
              TextField(
                controller: team1SetsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Sets won by ${team1['user1Name']} & ${team1['user2Name']}'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: team2SetsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Sets won by ${team2['user1Name']} & ${team2['user2Name']}'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final team1Sets = int.tryParse(team1SetsController.text) ?? 0;
                  final team2Sets = int.tryParse(team2SetsController.text) ?? 0;

                  setState(() {
                    final pools = _pools;
                    if (poolIndex >= 0 && poolIndex < pools.length) {
                      final pool = pools[poolIndex];
                      if (matchIndex >= 0 && matchIndex < pool.matches.length) {
                        pool.matches[matchIndex]['result'] = {
                          'setsTeam1': team1Sets,
                          'setsTeam2': team2Sets,
                        };
                        final poolGenerator = PoolGenerator();
                        poolGenerator.updateStandings(pool, matchIndex, team1Sets, team2Sets);
                        _pools = pools;
                      }
                    }
                  });

                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update({
                    'pools': _pools.map((pool) => pool.toMap()).toList(),
                  });
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }
}
