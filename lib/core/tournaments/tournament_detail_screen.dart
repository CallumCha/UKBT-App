import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';
import 'package:ukbtapp/core/tournaments/knockout_generator.dart';
import 'package:ukbtapp/core/tournaments/score_updater.dart';
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
  Map<String, List<Map<String, dynamic>>> _knockoutRounds = {
    'Quarter-finals': [],
    'Semi-finals': [],
    'Finals': []
  };
  int team1Sets = 0;
  int team2Sets = 0;

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
          // Debug print to understand the structure of tournamentData
          print("Tournament Data: $tournamentData");

          // Ensure that the data structures are correctly converted
          final teams = (tournamentData['teams'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          final teamDetails = await _fetchTeamDetails(teams);

          // Correctly handle pools data
          final poolsMap = tournamentData['pools'] as Map<String, dynamic>?;
          List<Pool> pools = [];

          if (poolsMap != null) {
            poolsMap.forEach((key, value) {
              if (value is List<dynamic>) {
                value.forEach((poolData) {
                  if (poolData is Map<String, dynamic>) {
                    pools.add(Pool.fromMap(poolData));
                  }
                });
              }
            });
          }

          setState(() {
            _tournamentData = tournamentData;
            _registrationOpen = tournamentData['registrationOpen'] ?? true;
            _teams = teamDetails;
            _pools = pools;
            _knockoutRounds['Quarter-finals'] = (tournamentData['quarterFinals'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
            _knockoutRounds['Semi-finals'] = (tournamentData['semiFinals'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
            _knockoutRounds['Finals'] = (tournamentData['finals'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          });
        }
      }
    } catch (e) {
      // Handle or log the error
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

  Future<void> _toggleRegistration() async {
    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);

    if (_registrationOpen) {
      // Generate pools and knockouts
      await _generatePoolsAndKnockouts();
    }

    await tournamentDoc.update({
      'registrationOpen': !_registrationOpen,
    });

    setState(() {
      _registrationOpen = !_registrationOpen;
    });
  }

  Future<void> _generatePoolsAndKnockouts() async {
    // Calculate team ELOs and sort teams by ELO
    _teams.sort((a, b) {
      final eloA = (int.parse(a.elo1) + int.parse(a.elo2)) / 2;
      final eloB = (int.parse(b.elo1) + int.parse(b.elo2)) / 2;
      return eloB.compareTo(eloA); // Sort in descending order
    });

    final poolGenerator = PoolGenerator();
    final pools = poolGenerator.createPools(_teams);
    final knockoutGenerator = KnockoutGenerator();
    final knockoutRounds = knockoutGenerator.createKnockouts(_teams.length);

    // Update the tournament document with pools and knockouts
    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
    await tournamentDoc.update({
      'pools': pools.map((pool) => pool.toMap()).toList(),
      'quarterFinals': knockoutRounds['Quarter-finals'],
      'semiFinals': knockoutRounds['Semi-finals'],
      'finals': knockoutRounds['Finals'],
    });

    setState(() {
      _pools = pools;
      _knockoutRounds = knockoutRounds;
    });
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
                    onChanged: (value) {
                      _toggleRegistration();
                    },
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
        bottomNavigationBar: _registrationOpen
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitRegistration,
                    child: const Text('Register'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDetailsTab() {
    return _tournamentData == null
        ? const Center(child: CircularProgressIndicator())
        : Padding(
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
                Expanded(
                  child: _teams.isEmpty
                      ? const Center(child: Text('No teams registered yet'))
                      : SingleChildScrollView(
                          child: Table(
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
                        ),
                ),
                if (_registrationOpen)
                  Padding(
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
                            onPressed: _addTeams,
                            child: const Text('Add Teams'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _buildPoolsTab() {
    return _pools.isEmpty
        ? const Center(child: Text('Pools will be generated once registration is closed'))
        : ListView.builder(
            itemCount: _pools.length,
            itemBuilder: (context, index) {
              final pool = _pools[index];
              final standings = pool.standings ?? [];
              return Card(
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
  }

  Widget _buildMatchesTab() {
    final tabs = [
      'Pool Matches'
    ];
    if (_knockoutRounds['Quarter-finals'] != null && _knockoutRounds['Quarter-finals']!.isNotEmpty) {
      tabs.add('Quarter-finals');
    }
    if (_knockoutRounds['Semi-finals'] != null && _knockoutRounds['Semi-finals']!.isNotEmpty) {
      tabs.add('Semi-finals');
    }
    if (_knockoutRounds['Finals'] != null && _knockoutRounds['Finals']!.isNotEmpty) {
      tabs.add('Finals');
    }

    return _pools.isEmpty
        ? const Center(child: Text('Matches will be generated once registration is closed'))
        : DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPoolMatchesTab(),
                      if (_knockoutRounds['Quarter-finals'] != null && _knockoutRounds['Quarter-finals']!.isNotEmpty) _buildKnockoutMatchesTab('Quarter-finals', _knockoutRounds['Quarter-finals']!),
                      if (_knockoutRounds['Semi-finals'] != null && _knockoutRounds['Semi-finals']!.isNotEmpty) _buildKnockoutMatchesTab('Semi-finals', _knockoutRounds['Semi-finals']!),
                      if (_knockoutRounds['Finals'] != null && _knockoutRounds['Finals']!.isNotEmpty) _buildKnockoutMatchesTab('Finals', _knockoutRounds['Finals']!),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPoolMatchesTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _pools.length,
            itemBuilder: (context, poolIndex) {
              final pool = _pools[poolIndex];
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
                          trailing: ElevatedButton(
                            onPressed: result == null ? () => _showScoreInputPopup(context, pool, matchIndex, match) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: result == null ? Colors.blue : Colors.grey,
                            ),
                            child: Text(result == null ? 'Input Score' : 'Score Inputted'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showGenerateKnockoutsPopup(context),
            child: const Text('Generate Knockouts'),
          ),
        ),
      ],
    );
  }

  Widget _buildKnockoutMatchesTab(String round, List<Map<String, dynamic>> matches) {
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final pool = _pools[index];
        final match = matches[index];
        final team1 = match['team1'];
        final team2 = match['team2'];
        final result = match['result'] as Map<String, int>?;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(team1 is Map<String, String> ? '${team1['user1Name']} & ${team1['user2Name']}' : team1.toString()),
                  trailing: result != null ? Text('${result['setsTeam1']} - ${result['setsTeam2']}') : const Text('0 - 0'),
                ),
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${match['team1']['user1Name']} & ${match['team1']['user2Name']}'),
                      Text('${match['team2']['user1Name']} & ${match['team2']['user2Name']}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: result == null ? () => _showScoreInputPopup(context, pool, index, match) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: result == null ? Colors.blue : Colors.grey,
                    ),
                    child: Text(result == null ? 'Input Score' : 'Score Inputted'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScoreInputPopup(BuildContext context, Pool pool, int matchIndex, Map<String, dynamic> match) {
    final team1 = match['team1'] as Map<String, dynamic>;
    final team2 = match['team2'] as Map<String, dynamic>;

    final TextEditingController team1SetsController = TextEditingController();
    final TextEditingController team2SetsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Match Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${team1['user1Name']} & ${team1['user2Name']} vs ${team2['user1Name']} & ${team2['user2Name']}'),
              TextField(
                controller: team1SetsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Sets won by ${team1['user1Name']} & ${team1['user2Name']}'),
              ),
              TextField(
                controller: team2SetsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Sets won by ${team2['user1Name']} & ${team2['user2Name']}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final team1Sets = int.tryParse(team1SetsController.text) ?? 0;
                final team2Sets = int.tryParse(team2SetsController.text) ?? 0;

                final scoreUpdater = ScoreUpdater(widget.tournamentId);
                await scoreUpdater.updateMatchResult(pool, matchIndex, team1Sets, team2Sets);

                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showGenerateKnockoutsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Knockouts'),
          content: const Text('This will generate the knockout matches. Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add your logic here for generating knockouts if needed
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
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
      'teams': FieldValue.arrayUnion(teams)
    }).then((_) {
      _fetchTournamentDetails(); // Refresh the tournament details after adding teams
    });
  }
}
