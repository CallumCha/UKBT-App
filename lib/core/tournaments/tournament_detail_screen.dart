import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ukbtapp/core/auth/auth_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  TournamentDetailScreen({required this.tournamentId});

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
  List<Map<String, String>> _teams = [];
  List<Map<String, dynamic>> _pools = [];
  List<String> _knockouts = [];

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
    final doc = await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
    if (doc.exists) {
      final tournamentData = doc.data();
      if (tournamentData != null) {
        final teams = List<Map<String, dynamic>>.from(tournamentData['teams'] ?? []);
        final teamDetails = await _fetchTeamDetails(teams);
        setState(() {
          _tournamentData = tournamentData;
          _registrationOpen = tournamentData['registrationOpen'] ?? true;
          _teams = teamDetails;
          _pools = List<Map<String, dynamic>>.from(tournamentData['pools'] ?? []);
          _knockouts = List<String>.from(tournamentData['knockouts'] ?? []);
        });
      }
    }
  }

  Future<List<Map<String, String>>> _fetchTeamDetails(List<Map<String, dynamic>> teams) async {
    List<Map<String, String>> teamDetails = [];
    for (var team in teams) {
      final String ukbtno1 = team['ukbtno1'].toString();
      final String ukbtno2 = team['ukbtno2'].toString();

      final user1Query = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtno1).get();
      final user2Query = await FirebaseFirestore.instance.collection('users').where('ukbtno', isEqualTo: ukbtno2).get();

      final user1Doc = user1Query.docs.isNotEmpty ? user1Query.docs.first : null;
      final user2Doc = user2Query.docs.isNotEmpty ? user2Query.docs.first : null;

      final user1Data = user1Doc?.data();
      final user2Data = user2Doc?.data();

      final user1Name = user1Data != null ? user1Data['name'] : 'Unknown';
      final user2Name = user2Data != null ? user2Data['name'] : 'Unknown';

      teamDetails.add({
        'user1Name': user1Name,
        'user2Name': user2Name,
        'ukbtno1': ukbtno1,
        'ukbtno2': ukbtno2,
        'elo1': user1Data != null ? user1Data['elo'].toString() : '0',
        'elo2': user2Data != null ? user2Data['elo'].toString() : '0',
      });
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
      final eloA = (int.parse(a['elo1']!) + int.parse(a['elo2']!)) / 2;
      final eloB = (int.parse(b['elo1']!) + int.parse(b['elo2']!)) / 2;
      return eloB.compareTo(eloA); // Sort in descending order
    });

    final numTeams = _teams.length;
    final pools = <Map<String, dynamic>>[];
    final knockouts = <String>[];

    // Generate pools based on the number of teams
    if (numTeams >= 5 && numTeams <= 12) {
      pools.addAll(_createPools(numTeams));
      knockouts.addAll(_createKnockouts(numTeams));
    }

    // Update the tournament document with pools and knockouts
    final tournamentDoc = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
    await tournamentDoc.update({
      'pools': pools,
      'knockouts': knockouts,
    });

    setState(() {
      _pools = pools;
      _knockouts = knockouts;
    });
  }

  // Generate pools based on the number of teams (you can adjust this logic based on your needs)
  List<Map<String, dynamic>> _createPools(int numTeams) {
    final pools = <Map<String, dynamic>>[];

    if (numTeams == 5) {
      pools.add(_createPool('Group A', _teams));
    } else if (numTeams == 6) {
      pools.add(_createPool('Group A', _teams.sublist(0, 3)));
      pools.add(_createPool('Group B', _teams.sublist(3, 6)));
    } else if (numTeams == 7) {
      pools.add(_createPool('Group A', _teams.sublist(0, 4)));
      pools.add(_createPool('Group B', _teams.sublist(4, 7)));
    } else if (numTeams == 8) {
      pools.add(_createPool('Group A', _teams.sublist(0, 4)));
      pools.add(_createPool('Group B', _teams.sublist(4, 8)));
    } else if (numTeams == 9) {
      pools.add(_createPool('Group A', _teams.sublist(0, 3)));
      pools.add(_createPool('Group B', _teams.sublist(3, 6)));
      pools.add(_createPool('Group C', _teams.sublist(6, 9)));
    } else if (numTeams == 10) {
      pools.add(_createPool('Group A', _teams.sublist(0, 5)));
      pools.add(_createPool('Group B', _teams.sublist(5, 10)));
    } else if (numTeams == 11) {
      pools.add(_createPool('Group A', _teams.sublist(0, 4)));
      pools.add(_createPool('Group B', _teams.sublist(4, 8)));
      pools.add(_createPool('Group C', _teams.sublist(8, 11)));
    } else if (numTeams == 12) {
      pools.add(_createPool('Group A', _teams.sublist(0, 3)));
      pools.add(_createPool('Group B', _teams.sublist(3, 6)));
      pools.add(_createPool('Group C', _teams.sublist(6, 9)));
      pools.add(_createPool('Group D', _teams.sublist(9, 12)));
    }

    return pools;
  }

  // Create pool with matches and standings
  Map<String, dynamic> _createPool(String name, List<Map<String, String>> teams) {
    final matches = _generatePoolMatches(teams);
    final standings = _generateStandings(teams);

    return {
      'name': name,
      'teams': teams,
      'matches': matches,
      'standings': standings,
    };
  }

  // Generate pool matches
  List<Map<String, dynamic>> _generatePoolMatches(List<Map<String, String>> teams) {
    final matches = <Map<String, dynamic>>[];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add({
          'team1': teams[i],
          'team2': teams[j],
          'result': null, // Result will be updated later
        });
      }
    }
    return matches;
  }

  // Generate standings
  List<Map<String, dynamic>> _generateStandings(List<Map<String, String>> teams) {
    final standings = teams.map((team) {
      return {
        'team': team,
        'mp': 0,
        'w': 0,
        'l': 0,
        'sWon': 0,
        'sLost': 0,
      };
    }).toList();

    // Sort standings by wins and sets difference
// Sort standings by wins and sets difference
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

    return standings;
  }

  // Generate knockout matches based on the number of teams (you can adjust this logic based on your needs)
  List<String> _createKnockouts(int numTeams) {
    final knockouts = <String>[];

    if (numTeams == 5) {
      knockouts.add('Semifinals: 1st vs 4th, 2nd vs 3rd');
      knockouts.add('Final: Winners of the semifinals');
    } else if (numTeams == 6 || numTeams == 7 || numTeams == 8) {
      knockouts.add('Semifinals: Winner Group A vs Runner-up Group B, Winner Group B vs Runner-up Group A');
      knockouts.add('Final: Winners of the semifinals');
    } else if (numTeams == 9 || numTeams == 11) {
      knockouts.add('Quarterfinals: Top 8 teams, seeded by group performance');
      knockouts.add('Semifinals: Winners of the quarterfinals');
      knockouts.add('Final: Winners of the semifinals');
    } else if (numTeams == 10 || numTeams == 12) {
      knockouts.add('Quarterfinals: Top 8 teams, seeded by group performance');
      knockouts.add('Semifinals: Winners of the quarterfinals');
      knockouts.add('Final: Winners of the semifinals');
    }

    return knockouts;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tournament Details'),
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
          bottom: TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Pools'),
              Tab(text: 'Knockouts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(),
            _buildPoolsTab(),
            _buildKnockoutsTab(),
          ],
        ),
        bottomNavigationBar: _registrationOpen
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitRegistration,
                    child: Text('Register'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDetailsTab() {
    return _tournamentData == null
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${_tournamentData?['name']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Date: ${_tournamentData?['date']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Level: ${_tournamentData?['level']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Location: ${_tournamentData?['location']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Gender: ${_tournamentData?['gender']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text('Teams Registered:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: _teams.isEmpty
                      ? Center(child: Text('No teams registered yet'))
                      : SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(),
                            columnWidths: {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(3),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Player 1', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
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
                                    child: Text(team['user1Name'] ?? 'Unknown'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(team['user2Name'] ?? 'Unknown'),
                                  ),
                                ]);
                              }).toList(),
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
                            decoration: InputDecoration(labelText: 'UKBT Number 1'),
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
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'UKBT Number 2'),
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
                          SizedBox(height: 20),
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
        ? Center(child: Text('Pools will be generated once registration is closed'))
        : ListView.builder(
            itemCount: _pools.length,
            itemBuilder: (context, index) {
              final pool = _pools[index];
              final standings = pool['standings'] ?? [];
              final matches = pool['matches'] ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pool['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(),
                        columnWidths: {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('MP', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
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
                          }).toList(),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ...matches.map<Widget>((match) {
                        final team1 = match['team1'];
                        final team2 = match['team2'];
                        final result = match['result'];
                        return ListTile(
                          title: Text('${team1['user1Name']} & ${team1['user2Name']} vs ${team2['user1Name']} & ${team2['user2Name']}'),
                          subtitle: result != null ? Text('Result: ${result['setsTeam1']}:${result['setsTeam2']}') : Text('Match not played yet'),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildKnockoutsTab() {
    return _knockouts.isEmpty
        ? Center(child: Text('Knockouts will be generated once registration is closed'))
        : ListView.builder(
            itemCount: _knockouts.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_knockouts[index]),
              );
            },
          );
  }
}
